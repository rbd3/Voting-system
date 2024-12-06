// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Ballot {
    struct Voter {
        uint weight;
        bool voted;
        address delegate;
        uint vote;
    }

    struct Proposals {
        bytes32 name;
        uint voteCount;
    }

    address public chairperson;
    mapping (address => Voter) public voters;
    Proposals[] public proposals;

    constructor(bytes32[] memory proposalNames) {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;

        for(uint i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposals({
                name: proposalNames[i],
                voteCount: 0}));
        }
    }

    function giveRightToVote(address voter) external {
        require(msg.sender == chairperson,
        "only chairperson can give right to vote");
        require(!voters[voter].voted, 
        "Voter already voted");
        require(voters[voter].weight == 0);
        voters[voter].weight = 1;
    }

    function delegate(address to) external {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "you have no rigth to vote");
        require(!sender.voted, "you already voted");
        require(to == msg.sender, "self-delegation isn't allowed");

        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;
            require(to != msg.sender, "Found loop in delegation");
        }

        Voter storage delegate_ = voters[to];
        //voter cannot delegate to account can't vote
        require(delegate_.weight >= 1);
        sender.voted = true;
        sender.delegate = to;

        if(delegate_.voted){
            // If the delegate did not vote yet,
            // add to her weight.
            proposals[delegate_.vote].voteCount += sender.weight; 
        } else {
            delegate_.weight += sender.weight;
        }
    }

    function vote(uint256 proposal) external {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "has no right to vote");
        require(!sender.voted, "already voted");
        sender.voted = true;
        sender.vote = proposal;

        proposals[proposal].voteCount += sender.weight;
    }

    function winningProposal() public view returns (uint winningProposal_){
        uint winningVoteCount = 0;
        for(uint i = 0; i < proposals.length; i++){
            if(proposals[i].voteCount > winningVoteCount){
                winningVoteCount = proposals[i].voteCount;
                winningProposal_ = i;
            }
        }
    }

    function winnerName() external view returns(bytes32 winnerName_){
        winnerName_ = proposals[winningProposal()].name;
    }
}