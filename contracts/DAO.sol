// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./SystemToken.sol";
import "./WrapToken.sol";

contract DAO {
    SystemToken public PROFI;
    WrapToken public RTK;
    uint public proposalCount;
    uint public PROFIprice = 3;
    uint public RTKprice = 2;

    constructor(
        address[] memory _initialUsers,
        address _SystemToken,
        address _WrapToken
    ) {
        PROFI = SystemToken(_SystemToken);
        RTK = WrapToken(_WrapToken);

        for (uint i = 0; i < _initialUsers.length; i++) {
            DAOmembers[_initialUsers[i]] = true;
        }
    }

    modifier onlyDAO() {
        require(DAOmembers[msg.sender] == true);
        _;
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
        Weighted
    }

    enum ProposalStatus {
        Active,
        Finished,
        Deleted
    }

    struct Proposal {
        address target;
        address proposer;
        uint startTime;
        uint endTime;
        uint votesFor;
        uint votesAgainst;
        uint valueForChange;
        uint needVotes;
        ProposalStatus status;
        ProposalType propType;
        Quorum quorum;
    }

    struct Delegation {
        uint proposalId;
        address to;
        uint value;
    }

    mapping(address => bool) private DAOmembers;
    mapping(uint => Proposal) internal proposals;
    mapping(uint => mapping(address => uint)) internal voterTokens;
    mapping(uint => mapping(address => uint)) internal delegatedValue;
    mapping(uint => address[]) internal proposalVoters;
    mapping(uint => address[]) internal proposalDelegaters;
    mapping(address => uint) internal delegatedWeight;
    mapping(address => Delegation[]) internal userDelegations;

    event CastVote(
        uint indexed _proposalId,
        bool _support,
        uint _value
    );
    event Delegated(uint indexed _proposalId, address _to, uint _value);

    //1
    function checkQuorum(uint _proposalId) internal view returns (bool) {
        Proposal storage p = proposals[_proposalId];

        uint totalVotes = p.votesFor + p.votesAgainst;
        if (totalVotes <= 0) return false;

        if (p.quorum == Quorum.Simple) {
            return p.votesFor * 2 > totalVotes;
        } else if (p.quorum == Quorum.Super) {
            return p.votesFor * 3 >= totalVotes * 2;
        } else if (p.quorum == Quorum.Weighted) {
            return p.votesFor > p.votesAgainst;
        }
        return false;
    }

    //2
    function createProposal(
        address target,
        uint duration,
        ProposalType propType,
        Quorum quorum,
        uint needVotes,
        uint valueForChange
    ) external onlyDAO returns (uint) {
        uint id = proposalCount++;
        Proposal storage p = proposals[id];

        p.target = target;
        p.proposer = msg.sender;
        p.startTime = block.timestamp;
        p.endTime = block.timestamp + (duration * 60);
        p.valueForChange = valueForChange;
        p.needVotes = needVotes;
        p.status = ProposalStatus.Active;
        p.propType = propType;
        p.quorum = quorum;

        if (p.propType == ProposalType.A || p.propType == ProposalType.B) {
            require(p.quorum == Quorum.Weighted);
        } else {
            require(p.quorum != Quorum.Weighted);
        }

        return id;
    }

    //3
    function vote(
        uint _proposalId,
        bool _support,
        uint _value
    ) external onlyDAO {
        Proposal storage p = proposals[_proposalId];

        voterTokens[_proposalId][msg.sender] = _value;
        proposalVoters[_proposalId].push(msg.sender);

        PROFI.transferFrom(msg.sender, address(this), _value);

        uint weight = (_value / PROFIprice) +
            (delegatedWeight[msg.sender] / RTKprice);

        if (_support) {
            p.votesFor += weight;
        } else {
            p.votesAgainst += weight;
        }

        if (p.needVotes >= p.votesFor && checkQuorum(_proposalId)) {
            if (p.propType == ProposalType.A || p.propType == ProposalType.B) {
                PROFI.transferFrom(address(this), p.target, p.needVotes);
            } else if (p.propType == ProposalType.C) {
                DAOmembers[p.target] = true;
            } else if (p.propType == ProposalType.D) {
                DAOmembers[p.target] = false;
            } else if (p.propType == ProposalType.E) {
                PROFIprice = p.valueForChange;
            } else if (p.propType == ProposalType.E) {
                RTKprice = p.valueForChange;
            }
       
        }
        emit CastVote(_proposalId, _support, _value);
    }

    //4
    function deleteProposal(uint _proposalId) external onlyDAO {
        Proposal storage p = proposals[_proposalId];
        require(p.proposer == msg.sender);
        p.status = ProposalStatus.Deleted;

        address[] memory voters = proposalVoters[_proposalId];
        for (uint i = 0; i < voters.length; i++) {
            address voter = voters[i];
            uint value = voterTokens[_proposalId][voter];
            if (value > 0) {
                PROFI.transfer(voter, value);
                voterTokens[_proposalId][voter] = 0;
            }
        }

        address[] memory delegaters = proposalDelegaters[_proposalId];
        for (uint i = 0; i < delegaters.length; i++) {
            address delegater = delegaters[i];
            uint value = delegatedValue[_proposalId][delegater];
            if (value > 0) {
                RTK.transfer(delegater, value);
                delegatedValue[_proposalId][delegater] = 0;
            }
        }
    }
    //5

    function buyRTK() external payable {
        uint value = msg.value / 1 ether;
        RTK.transferFrom(
            address(RTK),
            msg.sender,
            value * (10 ** RTK.decimals())
        );
    }
    //6

    function delegate(uint _proposalId, address _to, uint _value) external {
        RTK.transferFrom(msg.sender, address(this), _value);
        proposalDelegaters[_proposalId].push(msg.sender);
        delegatedValue[_proposalId][msg.sender] += _value;
        delegatedWeight[_to] += _value;
        userDelegations[msg.sender].push(
            Delegation({proposalId: _proposalId, to: _to, value: _value})
        );
        emit Delegated(_proposalId, _to, _value);
    }
    //7
    function isDAO(address addr) external view returns (bool) {
        return DAOmembers[addr];
    }

    //8
    function getMyDelegations() external view returns (Delegation[] memory) {
        return userDelegations[msg.sender];
    }

    //9
    function getProposal(
        uint _proposalId
    )
        external
        view
        returns (
            ProposalStatus status,
            Quorum quorum,
            ProposalType propType,
            uint endTime,
            uint votesFor,
            uint votesAgainst,
            address target,
            address proposer,
            uint needVotes,
            uint valueForChange
        )
    {
        Proposal storage p = proposals[_proposalId];
        return (
            p.status,
            p.quorum,
            p.propType,
            p.endTime,
            p.votesFor,
            p.votesAgainst,
            p.target,
            p.proposer,
            p.needVotes,
            p.valueForChange
        );
    }
}
