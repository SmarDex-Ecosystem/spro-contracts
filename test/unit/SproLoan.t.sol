// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import { Test } from "forge-std/Test.sol";

import { IERC721Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC721 } from "@openzeppelin/contracts/interfaces/IERC721.sol";
import { Base64 } from "solady/src/utils/Base64.sol";

import { T20 } from "test/helper/T20.sol";

import { SproLoan } from "src/spro/SproLoan.sol";
import { ISproTypes } from "src/interfaces/ISproTypes.sol";

contract SproLoanTest is Test {
    SproLoan loanToken;
    address alice = address(0xa11ce);
    mapping(uint256 => ISproTypes.Loan) internal _loans;

    function setUp() public virtual {
        loanToken = new SproLoan(address(this));
    }

    function setLoan(uint256 loanId, ISproTypes.Loan memory loan) public {
        _loans[loanId] = loan;
    }

    function getLoan(uint256 loanId) external view returns (ISproTypes.Loan memory loan_) {
        loan_ = _loans[loanId];
    }
}

/* -------------------------------------------------------------------------- */
/*                                 CONSTRUCTOR                                */
/* -------------------------------------------------------------------------- */

contract TestSproLoanConstructor is SproLoanTest {
    function test_correctNameSymbolOwner() external view {
        assertTrue(keccak256(abi.encodePacked(loanToken.name())) == keccak256("Spro Loan"));
        assertTrue(keccak256(abi.encodePacked(loanToken.symbol())) == keccak256("LOAN"));
        assertTrue(keccak256(abi.encodePacked(loanToken.owner())) == keccak256(abi.encodePacked(address(this))));
    }
}

/* -------------------------------------------------------------------------- */
/*                                    MINT                                    */
/* -------------------------------------------------------------------------- */

contract TestSproLoanMint is SproLoanTest {
    function test_RevertWhen_callerIsNotActiveLoanContract() external {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(alice)));
        vm.prank(alice);
        loanToken.mint(alice);
    }

    function test_increaseLastLoanId() external {
        uint256 lastLoanId = loanToken._lastLoanId();

        loanToken.mint(alice);

        uint256 lastLoanIdValue = loanToken._lastLoanId();
        assertTrue(lastLoanIdValue == lastLoanId + 1);
    }

    function test_mintLoanToken() external {
        vm.prank(address(this));
        uint256 loanId = loanToken.mint(alice);

        assertTrue(loanToken.ownerOf(loanId) == alice);
    }

    function test_returnLoanId() external {
        uint256 loanId = loanToken.mint(alice);
        assertTrue(loanId == 1);
    }

    function test_loanMintedEmitEvent() external {
        vm.expectEmit();
        emit IERC721.Transfer(address(0), alice, 1);

        loanToken.mint(alice);
    }
}

/* -------------------------------------------------------------------------- */
/*                                    BURN                                    */
/* -------------------------------------------------------------------------- */

contract TestSproLoanBurn is SproLoanTest {
    uint256 loanId;

    function setUp() public override {
        super.setUp();

        loanId = loanToken.mint(alice);
    }

    function test_RevertWhen_whenCallerIsNotStoredLoanContractForGivenLoanId() external {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        vm.prank(alice);
        loanToken.burn(loanId);
    }

    function test_burnLoanToken() external {
        loanToken.burn(loanId);

        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, loanId));
        loanToken.ownerOf(loanId);
    }

    function test_loanBurnedEmitEvent() external {
        vm.expectEmit();
        emit IERC721.Transfer(alice, address(0), loanId);

        loanToken.burn(loanId);
    }
}

/* -------------------------------------------------------------------------- */
/*                                  TOKEN URI                                 */
/* -------------------------------------------------------------------------- */

contract TestSproLoanTokenUri is SproLoanTest {
    uint256 loanId;
    T20 eth;
    T20 usd;

    function setUp() public override {
        super.setUp();

        loanId = loanToken.mint(alice);
        eth = new T20("ETH", "ETH");
        usd = new T20("USD", "USD");
    }

    function test_tokenUriReturnCorrectValue() external {
        setLoan(
            loanId,
            ISproTypes.Loan({
                status: ISproTypes.LoanStatus.RUNNING,
                lender: alice,
                borrower: alice,
                startTimestamp: uint40(1_742_203_988),
                loanExpiration: uint40(1_742_203_988 + 100 days),
                collateralAddress: address(eth),
                collateralAmount: 100 * 10 ** 18,
                creditAddress: address(usd),
                principalAmount: 200 * 10 ** 18,
                fixedInterestAmount: 10 * 10 ** 18
            })
        );
        string memory tokenUri = loanToken.tokenURI(loanId);
        string memory prefix = "data:application/json;base64,";
        bytes memory tokenUriBytes = bytes(tokenUri);
        bytes memory prefixBytes = bytes(prefix);

        // 1. Check if the tokenUri starts with the expected prefix
        bool startsWithPrefix = false;
        if (tokenUriBytes.length >= prefixBytes.length) {
            bool isMatch = true;
            for (uint256 i = 0; i < prefixBytes.length; i++) {
                if (tokenUriBytes[i] != prefixBytes[i]) {
                    isMatch = false;
                    break;
                }
            }
            startsWithPrefix = isMatch;
        }
        assertTrue(startsWithPrefix, "Token URI does not start with the expected data URI prefix.");

        // 2. Extract the Base64 encoded part (slice the prefix off)
        bytes memory base64EncodedBytes = new bytes(tokenUriBytes.length - prefixBytes.length);
        for (uint256 i = 0; i < base64EncodedBytes.length; i++) {
            base64EncodedBytes[i] = tokenUriBytes[i + prefixBytes.length];
        }
        string memory base64EncodedString = string(base64EncodedBytes);

        bytes memory tokenUriJson = Base64.decode(base64EncodedString);
        string memory keyName = ".description";
        bool keyExists = vm.keyExistsJson(string(tokenUriJson), keyName);
        assertTrue(keyExists, string.concat("JSON key '", keyName, "' not found in token URI metadata"));
        keyName = ".image";
        keyExists = vm.keyExistsJson(string(tokenUriJson), keyName);
        assertTrue(keyExists, string.concat("JSON key '", keyName, "' not found in token URI metadata"));
        keyName = ".attributes";
        keyExists = vm.keyExistsJson(string(tokenUriJson), keyName);
        assertTrue(keyExists, string.concat("JSON key '", keyName, "' not found in token URI metadata"));
    }
}
