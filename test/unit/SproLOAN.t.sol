// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { Test } from "forge-std/Test.sol";

import { IERC721Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { SproLOAN } from "src/spro/SproLOAN.sol";

contract SproLOANTest is Test {
    bytes32 internal constant LAST_LOAN_ID_SLOT = bytes32(uint256(6)); // `lastLoanId` property position
    bytes32 internal constant LOAN_CONTRACT_SLOT = bytes32(uint256(7)); // `loanContract` mapping position

    SproLOAN loanToken;
    address alice = address(0xa11ce);
    address activeLoanContract = address(0x01);

    function setUp() public virtual {
        loanToken = new SproLOAN(address(this));
    }
}

/* ------------------------------------------------------------ */
/*  CONSTRUCTOR                                              */
/* ------------------------------------------------------------ */

contract SproLOAN_Constructor_Test is SproLOANTest {
    function test_shouldHaveCorrectNameAndSymbol() external view {
        assertTrue(keccak256(abi.encodePacked(loanToken.name())) == keccak256("Spro LOAN"));
        assertTrue(keccak256(abi.encodePacked(loanToken.symbol())) == keccak256("LOAN"));
    }
}

/* ------------------------------------------------------------ */
/*  MINT                                                     */
/* ------------------------------------------------------------ */

contract SproLOAN_Mint_Test is SproLOANTest {
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

    function test_shouldMintLOANToken() external {
        vm.prank(address(this));
        uint256 loanId = loanToken.mint(alice);

        assertTrue(loanToken.ownerOf(loanId) == alice);
    }

    function test_shouldReturnLoanId() external {
        uint256 loanId = loanToken.mint(alice);
        assertTrue(loanId == 1);
    }

    function test_shouldEmitEvent_LOANMinted() external {
        vm.expectEmit(true, true, true, false);
        emit SproLOAN.LOANMinted(1, alice);

        loanToken.mint(alice);
    }
}

/* ------------------------------------------------------------ */
/*  BURN                                                     */
/* ------------------------------------------------------------ */

contract SproLOAN_Burn_Test is SproLOANTest {
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

    function test_shouldBurnLOANToken() external {
        loanToken.burn(loanId);

        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, loanId));
        loanToken.ownerOf(loanId);
    }

    function test_shouldEmitEvent_LOANBurned() external {
        vm.expectEmit(true, false, false, false);
        emit SproLOAN.LOANBurned(loanId);

        loanToken.burn(loanId);
    }
}

/* ------------------------------------------------------------ */
/*  TOKEN URI                                                */
/* ------------------------------------------------------------ */

contract SproLOAN_TokenUri_Test is SproLOANTest {
    string tokenUri;
    uint256 loanId;

    function setUp() public override {
        super.setUp();

        tokenUri = "test.uri.xyz";

        vm.mockCall(address(this), abi.encodeWithSignature("loanMetadataUri()"), abi.encode(tokenUri));

        loanId = loanToken.mint(alice);
    }

    function test_shouldCallLoanContract() external {
        vm.expectCall(address(this), abi.encodeWithSignature("loanMetadataUri()"));
        loanToken.tokenURI(loanId);
    }

    function test_shouldReturnCorrectValue() external view {
        string memory _tokenUri = loanToken.tokenURI(loanId);
        assertEq(tokenUri, _tokenUri);
    }
}
