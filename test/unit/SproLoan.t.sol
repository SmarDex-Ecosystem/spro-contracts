// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { Test } from "forge-std/Test.sol";

import { IERC721Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { SproLoan } from "src/spro/SproLoan.sol";
import { ISproLoan } from "src/interfaces/ISproLoan.sol";

contract SproLoanTest is Test {
    bytes32 internal constant LAST_LOAN_ID_SLOT = bytes32(uint256(6)); // `lastLoanId` property position
    bytes32 internal constant LOAN_CONTRACT_SLOT = bytes32(uint256(7)); // `loanContract` mapping position

    SproLoan loanToken;
    address alice = address(0xa11ce);
    address activeLoanContract = address(0x01);

    function setUp() public virtual {
        loanToken = new SproLoan(address(this));
    }
}

/* -------------------------------------------------------------------------- */
/*                                 CONSTRUCTOR                                */
/* -------------------------------------------------------------------------- */

contract SproLoan_Constructor_Test is SproLoanTest {
    function test_shouldHaveCorrectNameAndSymbol() external view {
        assertTrue(keccak256(abi.encodePacked(loanToken.name())) == keccak256("Spro Loan"));
        assertTrue(keccak256(abi.encodePacked(loanToken.symbol())) == keccak256("LOAN"));
    }
}

/* -------------------------------------------------------------------------- */
/*                                    MINT                                    */
/* -------------------------------------------------------------------------- */

contract SproLoan_Mint_Test is SproLoanTest {
    function test_shouldFail_whenCallerIsNotActiveLoanContract() external {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(alice)));
        vm.prank(alice);
        loanToken.mint(alice);
    }

    function test_shouldIncreaseLastLoanId() external {
        uint256 lastLoanId = loanToken.lastLoanId();

        loanToken.mint(alice);

        uint256 lastLoanIdValue = loanToken.lastLoanId();
        assertTrue(lastLoanIdValue == lastLoanId + 1);
    }

    function test_shouldMintLoanToken() external {
        vm.prank(address(this));
        uint256 loanId = loanToken.mint(alice);

        assertTrue(loanToken.ownerOf(loanId) == alice);
    }

    function test_shouldReturnLoanId() external {
        uint256 loanId = loanToken.mint(alice);
        assertTrue(loanId == 1);
    }

    function test_shouldEmitEvent_LoanMinted() external {
        vm.expectEmit(true, true, true, false);
        emit ISproLoan.LoanMinted(1, alice);

        loanToken.mint(alice);
    }
}

/* -------------------------------------------------------------------------- */
/*                                    BURN                                    */
/* -------------------------------------------------------------------------- */

contract SproLoan_Burn_Test is SproLoanTest {
    uint256 loanId;

    function setUp() public override {
        super.setUp();

        loanId = loanToken.mint(alice);
    }

    function test_shouldFail_whenCallerIsNotStoredLoanContractForGivenLoanId() external {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        vm.prank(alice);
        loanToken.burn(loanId);
    }

    function test_shouldBurnLoanToken() external {
        loanToken.burn(loanId);

        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, loanId));
        loanToken.ownerOf(loanId);
    }

    function test_shouldEmitEvent_LoanBurned() external {
        vm.expectEmit(true, false, false, false);
        emit ISproLoan.LoanBurned(loanId);

        loanToken.burn(loanId);
    }
}

/* -------------------------------------------------------------------------- */
/*                                  TOKEN URI                                 */
/* -------------------------------------------------------------------------- */

contract SproLoan_TokenUri_Test is SproLoanTest {
    string tokenUri;
    uint256 loanId;

    function setUp() public override {
        super.setUp();

        tokenUri = "test.uri.xyz";
        loanId = loanToken.mint(alice);
    }

    function test_shouldReturnCorrectValue() external {
        vm.mockCall(
            address(loanToken),
            abi.encodeWithSignature("tokenURI(uint256)", loanId),
            abi.encode(string.concat(tokenUri, Strings.toString(loanId)))
        );
        string memory _tokenUri = loanToken.tokenURI(loanId);
        assertEq(string.concat(tokenUri, Strings.toString(loanId)), _tokenUri);
    }
}
