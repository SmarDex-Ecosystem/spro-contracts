// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { Test } from "forge-std/Test.sol";

import { IERC721Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { IERC5646 } from "src/interfaces/IERC5646.sol";
import { PWNLOAN } from "spro/PWNLOAN.sol";

contract PWNLOANTest is Test {
    bytes32 internal constant LAST_LOAN_ID_SLOT = bytes32(uint256(6)); // `lastLoanId` property position
    bytes32 internal constant LOAN_CONTRACT_SLOT = bytes32(uint256(7)); // `loanContract` mapping position

    PWNLOAN loanToken;
    address alice = address(0xa11ce);
    address activeLoanContract = address(0x01);

    function setUp() public virtual {
        loanToken = new PWNLOAN(address(this));
    }

    function _loanContractSlot(uint256 loanId) internal pure returns (bytes32) {
        return keccak256(abi.encode(loanId, LOAN_CONTRACT_SLOT));
    }
}

/* ------------------------------------------------------------ */
/*  CONSTRUCTOR                                              */
/* ------------------------------------------------------------ */

contract PWNLOAN_Constructor_Test is PWNLOANTest {
    function test_shouldHaveCorrectNameAndSymbol() external view {
        assertTrue(keccak256(abi.encodePacked(loanToken.name())) == keccak256("PWN LOAN"));
        assertTrue(keccak256(abi.encodePacked(loanToken.symbol())) == keccak256("LOAN"));
    }
}

/* ------------------------------------------------------------ */
/*  MINT                                                     */
/* ------------------------------------------------------------ */

contract PWNLOAN_Mint_Test is PWNLOANTest {
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

    function test_shouldStoreLoanContractUnderLoanId() external {
        uint256 loanId = loanToken.mint(alice);
        address loanContract = loanToken.loanContract(loanId);

        assertTrue(loanContract == address(this));
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
        emit PWNLOAN.LOANMinted(1, address(this), alice);

        loanToken.mint(alice);
    }
}

/* ------------------------------------------------------------ */
/*  BURN                                                     */
/* ------------------------------------------------------------ */

contract PWNLOAN_Burn_Test is PWNLOANTest {
    uint256 loanId;

    function setUp() public override {
        super.setUp();

        loanId = loanToken.mint(alice);
    }

    function test_shouldFail_whenCallerIsNotStoredLoanContractForGivenLoanId() external {
        vm.expectRevert(abi.encodeWithSelector(PWNLOAN.InvalidLoanContractCaller.selector));
        vm.prank(alice);
        loanToken.burn(loanId);
    }

    function test_shouldDeleteStoredLoanContract() external {
        loanToken.burn(loanId);

        assertTrue(loanToken.loanContract(loanId) == address(0));
    }

    function test_shouldBurnLOANToken() external {
        loanToken.burn(loanId);

        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, loanId));
        loanToken.ownerOf(loanId);
    }

    function test_shouldEmitEvent_LOANBurned() external {
        vm.expectEmit(true, false, false, false);
        emit PWNLOAN.LOANBurned(loanId);

        loanToken.burn(loanId);
    }
}

/* ------------------------------------------------------------ */
/*  TOKEN URI                                                */
/* ------------------------------------------------------------ */

contract PWNLOAN_TokenUri_Test is PWNLOANTest {
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

/* ------------------------------------------------------------ */
/*  ERC5646                                                  */
/* ------------------------------------------------------------ */

contract PWNLOAN_GetStateFingerprint_Test is PWNLOANTest {
    uint256 loanId = 42;

    function test_shouldReturnZeroIfLoanDoesNotExist() external view {
        bytes32 fingerprint = loanToken.getStateFingerprint(loanId);

        assertEq(fingerprint, bytes32(0));
    }
}

/* ------------------------------------------------------------ */
/*  ERC165                                                   */
/* ------------------------------------------------------------ */

contract PWNLOAN_SupportsInterface_Test is PWNLOANTest {
    function test_shouldSupportERC5646() external view {
        assertTrue(loanToken.supportsInterface(type(IERC5646).interfaceId));
    }
}
