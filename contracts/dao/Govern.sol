/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>
    Copyright 2021 vsdcrew <vsdcrew@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Setters.sol";
import "./Permission.sol";
import "./Upgradeable.sol";
import "../external/Require.sol";
import "../external/Decimal.sol";
import "../Constants.sol";

contract Govern is Setters, Permission, Upgradeable {
    using SafeMath for uint256;
    using Decimal for Decimal.D256;

    bytes32 private constant FILE = "Govern";

    event Proposal(uint256 indexed candidate, address indexed account, uint256 indexed start, uint256 period);
    event Vote(address indexed account, uint256 indexed candidate, Candidate.Vote vote, uint256 bondedVotes);
    event Commit(address indexed account, uint256 indexed candidate, bool upgrade);

    /*
     * We allow voting as long as the token is bonded.
     */
    function vote(uint256 candidate, Candidate.Vote vote) external {
        Require.that(
            msg.sender == tx.origin,
            FILE,
            "Must be a user tx"
        );

        if (!isNominated(candidate)) {
            Require.that(
                canPropose(msg.sender),
                FILE,
                "Not enough stake to propose"
            );

            createCandidate(candidate, Constants.getGovernancePeriod());
            emit Proposal(candidate, msg.sender, epoch(), Constants.getGovernancePeriod());
        }

        Require.that(
            epoch() < startFor(candidate).add(periodFor(candidate)),
            FILE,
            "Ended"
        );

        uint256 bondedVotes = balanceOfBondedDollar(msg.sender);
        Candidate.VoteInfo memory recordedVoteInfo = recordedVoteInfo(msg.sender, candidate);
        Candidate.VoteInfo memory newVoteInfo = Candidate.VoteInfo({vote: vote, bondedVotes: bondedVotes});

        if (newVoteInfo.vote == recordedVoteInfo.vote && newVoteInfo.bondedVotes == recordedVoteInfo.bondedVotes) {
            return;
        }

        if (recordedVoteInfo.vote == Candidate.Vote.REJECT) {
            decrementRejectFor(candidate, recordedVoteInfo.bondedVotes);
        }
        if (recordedVoteInfo.vote == Candidate.Vote.APPROVE) {
            decrementApproveFor(candidate, recordedVoteInfo.bondedVotes);
        }
        if (vote == Candidate.Vote.REJECT) {
            incrementRejectFor(candidate, newVoteInfo.bondedVotes);
        }
        if (vote == Candidate.Vote.APPROVE) {
            incrementApproveFor(candidate, newVoteInfo.bondedVotes);
        }

        recordVoteInfo(msg.sender, candidate, newVoteInfo);
        placeLock(msg.sender, candidate);

        emit Vote(msg.sender, candidate, vote, bondedVotes);
    }

    function commit(uint256 candidate) external {
        Require.that(
            isNominated(candidate),
            FILE,
            "Not nominated"
        );

        uint256 endsAfter = startFor(candidate).add(periodFor(candidate)).sub(1);

        Require.that(
            epoch() > endsAfter,
            FILE,
            "Not ended"
        );

        Require.that(
            epoch() <= endsAfter.add(1).add(Constants.getGovernanceExpiration()),
            FILE,
            "Expired"
        );

        Require.that(
            Decimal.ratio(votesFor(candidate), dollar().totalSupply()).greaterThan(Constants.getGovernanceQuorum()),
            FILE,
            "Must have quorom"
        );

        Require.that(
            approveFor(candidate) > rejectFor(candidate),
            FILE,
            "Not approved"
        );

        Require.that(
            msg.sender == getGovernor(),
            FILE,
            "Must from governor"
        );

        upgradeTo(address(candidate));

        emit Commit(msg.sender, candidate, true);
    }

    function emergencyCommit(uint256 candidate) external {
        Require.that(
            isNominated(candidate),
            FILE,
            "Not nominated"
        );

        Require.that(
            Decimal.ratio(approveFor(candidate), dollar().totalSupply()).greaterThan(Constants.getGovernanceSuperMajority()),
            FILE,
            "Must have super majority"
        );

        Require.that(
            approveFor(candidate) > rejectFor(candidate),
            FILE,
            "Not approved"
        );

        Require.that(
            msg.sender == getGovernor(),
            FILE,
            "Must from governor"
        );

        upgradeTo(address(candidate));

        emit Commit(msg.sender, candidate, true);
    }

    function canPropose(address account) private view returns (bool) {
        Decimal.D256 memory stake = Decimal.ratio(
            balanceOfBondedDollar(account),
            dollar().totalSupply()
        );
        return stake.greaterThan(Constants.getGovernanceProposalThreshold());
    }

    function getGovernor() internal view returns (address) {
        return Constants.getGovernor();
    }
}
