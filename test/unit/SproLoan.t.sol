// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import { Test, console2 } from "forge-std/Test.sol";

import { IERC721Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";

import { T20 } from "test/helper/T20.sol";

import { SproLoan } from "src/spro/SproLoan.sol";
import { ISproTypes } from "src/interfaces/ISproTypes.sol";
import { ISproLoan } from "src/interfaces/ISproLoan.sol";

contract SproLoanTest is Test {
    SproLoan loanToken;
    address alice = address(0xa11ce);
    mapping(uint256 => ISproTypes.Loan) internal _loans;

    function setUp() public virtual {
        loanToken = new SproLoan(address(this));
    }

    function setLoan(uint256 loanId, ISproTypes.Loan memory loan_) public {
        _loans[loanId] = loan_;
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
        vm.expectEmit(true, true, true, false);
        emit ISproLoan.LoanMinted(1, alice);

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
        vm.expectEmit(true, false, false, false);
        emit ISproLoan.LoanBurned(loanId);

        loanToken.burn(loanId);
    }
}

/* -------------------------------------------------------------------------- */
/*                                  TOKEN URI                                 */
/* -------------------------------------------------------------------------- */

contract TestSproLoanTokenUri is SproLoanTest {
    string tokenUri;
    uint256 loanId;
    T20 eth;
    T20 usd;

    function setUp() public override {
        super.setUp();

        tokenUri = "test.uri.xyz/";
        loanId = loanToken.mint(alice);
        eth = new T20("ETH", "ETH");
        usd = new T20("USD", "USD");
    }

    function test_tokenUriReturnCorrectValue() external {
        loanToken.setLoanMetadataUri(tokenUri);
        setLoan(
            loanId,
            ISproTypes.Loan({
                status: ISproTypes.LoanStatus.RUNNING,
                lender: alice,
                borrower: alice,
                startTimestamp: uint40(1_742_203_988),
                loanExpiration: uint40(1_742_203_988 + 100 days),
                collateral: address(eth),
                collateralAmount: 100,
                credit: address(usd),
                principalAmount: 200,
                fixedInterestAmount: 10 * 10 ** 18
            })
        );
        string memory _tokenUri = loanToken.tokenURI(loanId);
        console2.log("_tokenUri", _tokenUri);
    }

    function test_loanMetadataUri() external view {
        string memory uri = loanToken._metadataUri();
        assertEq(uri, "");
    }

    function test_loanMetadataUriUpdatedEmitEvent() external {
        vm.expectEmit(true, true, true, true);
        emit ISproLoan.LoanMetadataUriUpdated(tokenUri);
        emit IERC4906.BatchMetadataUpdate(0, type(uint256).max);

        loanToken.setLoanMetadataUri(tokenUri);
    }
}
