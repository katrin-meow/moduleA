// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import "./SystemToken.sol";
import "./WrapToken.sol";

contract DAO {
    SystemToken public PROFI;
    WrapToken public RTK;
    uint public PROFIprice = 3;
    uint public RTKprice = 2;
    uint public proposalCount;

    constructor(
        address[] memory _initialUsers,
        address _SystemToken,
        address _WrapToken
    ) {
        PROFI = SystemToken(_SystemToken);
        RTK = WrapToken(_WrapToken);
        for (uint i = 0; i < _initialUsers.length; i++) {
            DAOmem[_initialUsers[i]] = true;
        }
    }
   
    mapping(address => bool) private DAOmem;
    mapping(uint => Proposal) internal proposals;
    mapping(uint => mapping(address => uint)) internal voterTokens;
    mapping(uint => address[]) internal proposalVoters;
    mapping(uint => address[]) internal proposalDelegate;
    mapping(uint => mapping(address => uint)) internal delegateAmount;
    mapping(address => uint) internal delegatedWeight;

    enum ProposalStatus {
        Active,
        Finished,
        Deleted
    }

    enum ProposalType {
        A,
        B,
        C,
        D,
        E,
        F
    }

    enum Quorum {
        Simple,
        Super,
        Weighed
    }

    struct Delegation {
        address to;
        uint value;
    }

    struct Proposal {
        ProposalStatus status;
        ProposalType proposalType;
        Quorum quorum;
        address proposer;
        address target;
        uint startTime;
        uint endTime;
        uint votesFor;
        uint votesAgainst;
        bool isDeleted;
        bool isExecuted;
        uint valueForChange;
        uint needVotes;
    }

    event ProposalCreated(uint indexed _proposalId, ProposalType proposalType);

    event Executed(uint indexed _proposalId);

    event CastVote(
        address _voter,
        bool _support,
        uint _value,
        uint indexed _proposalId
    );

    event Delegated(
        address from,
        address _to,
        uint _value,
        uint indexed _proposalId
    );

    modifier OnlyDAOmem() {
        require(DAOmem[msg.sender] = true, "d");
        _;
    }

    function buyRTK() external payable {
        require(msg.value > 0, "value must be more than zero");
        uint rtkAmount = msg.value / 1 ether; 
        RTK.transferFrom(
            address(RTK),
            msg.sender,
            rtkAmount * (10 ** RTK.decimals())
        ); 
    }

    function checkQuorum(uint _proposalId) internal view returns (bool) {
        Proposal storage p = proposals[_proposalId];
        uint totalValue = p.votesFor + p.votesAgainst;
        if (p.quorum == Quorum.Simple) {
            return p.votesFor > p.votesAgainst;
        } else if (p.quorum == Quorum.Super) {
            if (totalValue == 0) return false;
            return p.votesFor * 2 > totalValue;
        } else if (p.quorum == Quorum.Weighed) {
            if (totalValue == 0) return false;
            return p.votesFor * 3 >= totalValue * 2;
        }
        return false;
    }
    
    function createProposal(
        ProposalType _proposalType,
        uint _durationMin,
        uint _valueForChange,
        address _target,
        uint _needVotes,
        Quorum _quorum
    ) external OnlyDAOmem returns (uint) {
        require(_durationMin > 0, "jf");
        uint id = proposalCount++;
        Proposal storage p = proposals[id];
        p.proposalType = _proposalType;
        p.status = ProposalStatus.Active;
        p.quorum = _quorum;
        p.proposer = msg.sender;
        p.target = _target;
        p.valueForChange = _valueForChange;
        p.needVotes = _needVotes;
        p.startTime = block.timestamp;
        p.endTime = block.timestamp + _durationMin * 60;
        if (
            p.proposalType == ProposalType.A || p.proposalType == ProposalType.B
        ) {
            require(_quorum == Quorum.Weighed);
        } else {
            require(_quorum != Quorum.Weighed);
        }
        emit ProposalCreated(id, _proposalType);
        return id;
    }
    
    function vote(uint _proposalId, bool _support, uint _value) external {
        Proposal storage p = proposals[_proposalId];
        require(_value > 0);
        require(block.timestamp < p.endTime);

        PROFI.transferFrom(msg.sender, address(this), _value);

        uint _weight = (_value / PROFIprice) +
            (delegatedWeight[msg.sender] / RTKprice);

        proposalVoters[_proposalId].push(msg.sender);
        voterTokens[_proposalId][msg.sender] = _value;

        if (_support) {
            p.votesFor += _weight;
        } else {
            p.votesAgainst += _weight;
        }
        if (p.needVotes > p.votesFor && checkQuorum(_proposalId)) {
            if (
                p.proposalType == ProposalType.A ||
                p.proposalType == ProposalType.B
            ) {
                PROFI.transferFrom(address(this), p.target, p.needVotes);
            } else if (p.proposalType == ProposalType.C) {
                DAOmem[p.target] = true;
            } else if (p.proposalType == ProposalType.D) {
                DAOmem[p.target] = false;
            } else if (p.proposalType == ProposalType.E) {
                PROFIprice = p.valueForChange;
            } else if (p.proposalType == ProposalType.F) {
                RTKprice = p.valueForChange;
            }
        }
        p.isExecuted = true;
        emit CastVote(msg.sender, _support, _weight, _proposalId);
        emit Executed(_proposalId);
    }
    
    function delegate(address _to, uint _value, uint _proposalId) external {
        require(_to != address(0), "invalid address");
        require(_value > 0);
        RTK.transferFrom(msg.sender, address(this), _value);
        proposalDelegate[_proposalId].push(msg.sender);
        delegateAmount[_proposalId][msg.sender] += _value;
        delegatedWeight[_to] += _value;
    }
    
    function deleteProposal(uint _proposalId) external OnlyDAOmem {
        Proposal storage p = proposals[_proposalId];
        require(p.proposer == msg.sender);
        require(block.timestamp <= p.endTime);
        require(!p.isDeleted);
        p.isDeleted = true;
        p.status = ProposalStatus.Deleted;

        address[] memory voters = proposalVoters[_proposalId];
        for (uint i = 0; i < voters.length; i++) {
            address voter = voters[i];
            uint amount = voterTokens[_proposalId][voter];
            if (amount > 0) {
                PROFI.transfer(voter, amount);
                voterTokens[_proposalId][voter] = 0;
            }
        }

        address[] memory delegateVoters = proposalDelegate[_proposalId];
        for (uint256 i = 0; i < delegateVoters.length; i++) {
            address delegator = delegateVoters[i];
            uint256 amount = delegateAmount[_proposalId][delegator];

            if (amount > 0) {
                RTK.transferFrom(address(this), delegator, amount);
                delegateAmount[_proposalId][delegator] = 0;
            }
        }
    }
     function isDAOmember(address user) external view returns (bool) {
        return DAOmem[user];
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
            Quorum quorumMechanism,
            ProposalType proposalType,
            address proposer,
            address target,
            uint votesFor,
            uint votesAgainst
        )
    {
        Proposal storage p = proposals[_proposalId];
        return (
            p.status,
            p.startTime,
            p.endTime,
            p.quorum,
            p.proposalType,
            p.proposer,
            p.target,
            p.votesFor,
            p.votesAgainst
        );
    }
}
