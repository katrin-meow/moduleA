// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;
import "./SystemToken.sol";
import "./WrapToken.sol";

contract DAO {
    SystemToken public PROFI;
    WrapToken public RTK;

    uint public PROFIprice = 3; //стоимость голоса в системных токенах
    uint public RTKprice = 6; //стоимость голоса во врап токенах
    uint public proposalCount; //счетчик голосований
    constructor(
        address _SystemToken,
        address _WrapToken,
        address[] memory _initialUsers
    ) {
        RTK = WrapToken(_WrapToken);
        PROFI = SystemToken(_SystemToken);

        for (uint i = 0; i < _initialUsers.length; i++) {
            DAOmembers[_initialUsers[i]] = true; //при деплое введенные акки становятся участниками системы
        }
    }
    enum ProposalType {
        A, //инвестирование в новый стартап - 0
        B, //инвестирование в стартап, в который до этого уже вкладывались - 1
        C, //добавление нового участника системы - 2
        D, //искючение участника из система - 3
        E, //управление системным токеном - 4
        F //управление врап токеном - 5
    }

    enum ProposalStatus {
        Active, //принято решение
        Finished, //не принято
        Deleted //удален
    }

    enum QuorumMechanism {
        Simple, //50% + 1 голос (C,D,E,F)
        Super, // 2/3 голосов (С,D,E,F)
        Weighted //зависит от колва токенов (A,B)
    }
    struct Proposal {
        ProposalStatus status; //статус голосования
        uint startTime; //нечало голосования
        uint endTime; //конец голосования
        address proposer; //кто инициировал
        address target; //в пользу кого было создано голосование (перевод средств)
        uint votesFor; //кол-во голосов "за"
        uint votesAgainst; //кол-во голосов "против"
        QuorumMechanism quorumMechanism; //механизм достижения кворума
        ProposalType proposalType; //тип голосования
        bool isExecuted; //голосование исполнено?
        bool isDeleted; //голосование удалено?
        uint valueForChange; //значение для изменения курса токена
        uint valueForProposal; //значение для достижения кворума
        mapping(address => bool) hasVoted; //адрес уже голосовал?
    }

    struct Delegation {
        address to; //кому делегировал
        uint value; //сколько делегировал
    }
    mapping(uint => Proposal) internal proposals; //счетчик голосований
    mapping(address => bool) private DAOmembers; //члены системы

    mapping(uint => address[]) internal proposalVoters; //кто голосовал
    mapping(uint => mapping(address => uint)) internal voterTokens; //кто и скок токенов внес на голосование

    mapping(uint => address[]) internal delegatedProposal; //перечень адресов, которые делегировали в конкретном голосовании (по айди)
    mapping(uint => mapping(address => uint)) internal delegatedWeight; //айди пропосола => кто и скок делегировал
    mapping(address => uint) internal delegatedRTK; //скок врап токенов делегировал адрес
    mapping(address => mapping(uint => Delegation[])) internal userDelegations; //делегации юзера по его адресу

    event ProposalCreated(uint indexed proposalId, ProposalType proposalType);
    event Executed(uint indexed proposalId);
    event Delegated(
        address indexed from,
        address indexed to,
        uint indexed proposalId,
        uint value
    );
    event CastVote(
        address indexed voter,
        uint indexed proposalId,
        bool support,
        uint weight
    );

    modifier OnlyDAOmember() {
        require(DAOmembers[msg.sender], "not a DAO member");
        _;
    }
    modifier validTarget(address target) {
        require(target != address(0), "invalid target");
        _;
    }
    //  ----------- ПОКУПКА ВРАП ТОКЕНА -------------
    function buyRTK() external payable {
        require(msg.value > 0, "send ETH");
        uint amountToBuy = msg.value / 1 ether; //кол-во ртк по курсу 1 ртк = 1 эфир
        uint rtkBalance = RTK.balanceOf(RTK.owner()); //проверка наличия ртк токенов на балансе овнера (у него totalSupply)
        require(rtkBalance >= amountToBuy, "not enough rtk");
        bool ok = RTK.transfer(msg.sender, amountToBuy);
        require(ok, "d");
    }
    //  ----------- УДАЛЕНИЕ ПРЕДЛОЖЕНИЯ И ВОЗВРАТ ТОКЕНОВ -------------
    function deleteProposal(uint _proposalId) external OnlyDAOmember {
        Proposal storage p = proposals[_proposalId];
        require(block.timestamp <= p.endTime, "proposal already finished");
        require(msg.sender == p.proposer, "not a proposer");
        require(!p.isDeleted, "already deleted");

        p.isDeleted = true;
        p.status = ProposalStatus.Deleted;

        address[] memory voters = proposalVoters[_proposalId]; //возврат системных токенов участникам системы
        for (uint i = 0; i < voters.length; i++) {
            address voter = voters[i];
            uint amount = voterTokens[_proposalId][voter];
            if (amount > 0) {
                PROFI.transfer(voter, amount);
                voterTokens[_proposalId][voter] = 0;
            }
        }
        address[] memory delegaters = proposalVoters[_proposalId]; //возврат ртк токенов не участникам системы
        for (uint i = 0; i < delegaters.length; i++) {
            address delegater = delegaters[i];
            uint delegateAmount = delegatedWeight[_proposalId][delegater];
            if (delegateAmount > 0) {
                RTK.transfer(delegater, delegateAmount);
                delegatedWeight[_proposalId][delegater] = 0;
            }
        }
    }
    //  ----------- КВОРУМ -------------
    function checkQuorum(uint _proposalId) internal view returns (bool) {
        Proposal storage p = proposals[_proposalId];
        uint totalVotes = p.votesFor + p.votesAgainst;

        if (p.quorumMechanism == QuorumMechanism.Weighted) {
            return p.votesFor > p.votesAgainst;
        } else if (p.quorumMechanism == QuorumMechanism.Simple) {
            if (totalVotes == 0) return false;
            return p.votesFor * 2 > totalVotes;
        } else if (p.quorumMechanism == QuorumMechanism.Super) {
            if (totalVotes == 0) return false;
            return p.votesFor * 3 >= totalVotes * 2;
        }
        return false;
    }
    //  ----------- ДЕЛЕГИРОВАНИЕ ГОЛОСА -------------
    function delegate(address _to, uint _proposalId, uint _weight) external {
        require(_to != msg.sender, "can not delegate to self");
        require(_weight != 0, "weight must be more than 0");
        delegatedWeight[_proposalId][_to] += _weight;
        userDelegations[msg.sender][_proposalId].push(
            Delegation({to: _to, value: _weight})
        );

        emit Delegated(msg.sender, _to, _proposalId, _weight);
    }
    //  ----------- ИНИЦИИРОВАТЬ ПРЕДЛОЖЕНИЕ -------------
    function createProposal(
        ProposalType _proposalType,
        QuorumMechanism _quorumMechanism,
        uint _durationMinutes,
        uint _valueForProposal,
        uint _valueForChange,
        address _target
    ) external OnlyDAOmember returns (uint256) {
        require(_durationMinutes > 0, "duration must be more than 0");
        uint id = proposalCount++;
        Proposal storage p = proposals[id];
        p.proposalType = _proposalType;
        p.quorumMechanism = _quorumMechanism;
        p.valueForChange = _valueForChange;
        p.valueForProposal = _valueForProposal;
        p.target = _target;
        p.proposer = msg.sender;
        p.status = ProposalStatus.Active;
        p.startTime = block.timestamp;
        p.endTime = block.timestamp + _durationMinutes * 60;

        if (
            _proposalType == ProposalType.A || _proposalType == ProposalType.B //проверка на соответствие типа голосования и выбранного механизма достижения кворума
        ) {
            require(
                _quorumMechanism == QuorumMechanism.Weighted,
                "A and B type must be Weighted"
            );
        } else {
            require(
                _quorumMechanism != QuorumMechanism.Weighted,
                "can not be Weighed"
            );
        }
        emit ProposalCreated(id, _proposalType);
        return id;
    }
    //  ----------- ГОЛОСОВАНИЕ -------------
    function vote(uint _proposalId, uint _tokenAmount, bool _support) external {
        Proposal storage p = proposals[_proposalId];

        require(block.timestamp < p.endTime, "voting finished");
        require(!p.hasVoted[msg.sender], "already voted");
        require(_tokenAmount > 0, "amount must be nore than 0");

        PROFI.transferFrom(msg.sender, address(this), _tokenAmount);
        RTK.transferFrom(msg.sender, address(this), _tokenAmount);

        uint weight = (_tokenAmount / PROFIprice) +
            (delegatedRTK[msg.sender] / RTKprice); //вес голоса

        proposalVoters[_proposalId].push(msg.sender);
        voterTokens[_proposalId][msg.sender] = _tokenAmount;

        if (_support) {
            p.votesFor += weight;
        } else {
            p.votesAgainst += weight;
        }
        if (p.valueForProposal <= p.votesFor && checkQuorum(_proposalId)) {
            if (
                p.proposalType == ProposalType.A ||
                p.proposalType == ProposalType.B
            ) {
                PROFI.transferFrom(address(this), p.target, p.valueForProposal); // A - инвестирование в новый стартап || B - инвестирование в стартап, в который до этого уже вкладывались
            } else if (p.proposalType == ProposalType.C) {
                DAOmembers[p.target] = true; //C - добавление нового участника системы
            } else if (p.proposalType == ProposalType.D) {
                DAOmembers[p.target] = false; //  D - искючение участника из система
            } else if (p.proposalType == ProposalType.E) {
                PROFIprice = p.valueForChange; // E - управление системным токеном
            } else if (p.proposalType == ProposalType.F) {
                RTKprice = p.valueForChange; // F - управление врап токеном
            }
        }
        p.hasVoted[msg.sender] = true;
        emit CastVote(msg.sender, _proposalId, _support, weight);
        emit Executed(_proposalId);
    }
    //  ----------- ПРОВЕРКА НА УЧАСТНИКА СИСТЕМА -------------
    function isDAOMember(address _addr) external view returns (bool) {
        return DAOmembers[_addr];
    }
    //  ----------- ВЬЮШКИ -------------
    function getMyDelegations(
        uint _proposalId
    ) external view returns (Delegation[] memory) {
        return userDelegations[msg.sender][_proposalId];
    }
    function getProposals(
        uint _proposalId
    )
        external
        view
        returns (
            ProposalStatus status,
            uint startTime,
            uint endTime,
            QuorumMechanism quorumMechanism,
            ProposalType proposalType,
            address proposer,
            address target
        )
    {
        Proposal storage p = proposals[_proposalId];
        return (
            p.status,
            p.startTime,
            p.endTime,
            p.quorumMechanism,
            p.proposalType,
            p.proposer,
            p.target
        );
    }
}
