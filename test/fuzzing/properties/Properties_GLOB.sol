// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { FuzzStorageVariables } from "../utils/FuzzStorageVariables.sol";

import { Spro } from "src/spro/Spro.sol";

contract Properties_GLOB is FuzzStorageVariables {
    function invariant_GLOB_01() internal {
        emit log_address(credit);
        emit log_address(collateral);
        emit log_address(actors.lender);
        emit log_address(address(spro));
        emit log_uint(state[1].actorStates[address(spro)][credit]);
        emit log_uint(creditFromLoansPaidBack[credit]);
        emit log_uint(collateralFromProposals[credit]);
        emit log_uint(tokenMintedToProtocol[credit]);
        emit log_uint(tokenReceivedByProtocol[credit]);
        assert(
            state[1].actorStates[address(spro)][credit]
                == creditFromLoansPaidBack[credit] + collateralFromProposals[credit] + tokenMintedToProtocol[credit]
                    + tokenReceivedByProtocol[credit]
        );
    }

    function invariant_GLOB_02() internal {
        emit log_address(collateral);
        emit log_address(actors.lender);
        emit log_address(address(spro));
        emit log_uint(state[1].actorStates[address(spro)][collateral]);
        emit log_uint(
            collateralFromProposals[collateral] + creditFromLoansPaidBack[collateral]
                + tokenMintedToProtocol[collateral] + tokenReceivedByProtocol[collateral]
        );
        emit log_uint(collateralFromProposals[collateral]);
        emit log_uint(creditFromLoansPaidBack[collateral]);
        emit log_uint(tokenMintedToProtocol[collateral]);
        emit log_uint(tokenReceivedByProtocol[collateral]);
        assert(
            state[1].actorStates[address(spro)][collateral]
                == collateralFromProposals[collateral] + creditFromLoansPaidBack[collateral]
                    + tokenMintedToProtocol[collateral] + tokenReceivedByProtocol[collateral]
        );
    }
}
