// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MochaToken is ERC20("MochaToken", "MOCHA"), Ownable {
    
    /**
    * Additions to the MOCHA token to have it burn and mint tokens on tx's
    * 
    */
    /// @dev This address is will be used to send 0.1% of the MOCHA tokens to.
    address public rewardAddress;
    /**
     * @dev admin address is used to take care of the whitelisting process once
     * ownership is transfered to MasterChef
     */ 
    address public admin;

    /// @dev These are used to calcualte how much of the token is to be burned.
    uint constant public BURN_FEE = 900;
    uint constant public REWARD_FEE = 100;
    uint constant public MAX_FEE = 100000;
    uint256 constant public HARD_CAP = 10 ** 7 * 1e18;
    
    /// @dev List of whitelisted addresses
    mapping (address => bool) public whiteList;

    event WhiteList(address account, bool status);
    event SetRewardAddress(address caller, address newRewardAddress);

    // Check which makes sure that the HARD_CAP wasn't reached 
    modifier checkHardCap(uint256 amount) {
        require(totalSupply().add(amount) <= HARD_CAP, "Supply is greater than 10 mil");
        _;
    }

    // Check to make sure only the admin can access the WhiteList function
    modifier onlyAdmin(){
        require(admin == msg.sender, "Caller not Admin!");
        _;
    }

    /**
     * @dev Sets the values for {rewardAddress} which is the address of
     * of the reward pool. It's best to set the {admin} address manually
     * just incase a deployer contract is used.
     */
    constructor (address _rewardAddress, address _admin) public {
        rewardAddress = _rewardAddress;
        admin = _admin;
    }

    /// @notice This is where the address of the reward pool is set.
    function setRewardAddress(address _rewardAddress) public onlyOwner {
        rewardAddress = _rewardAddress;
        emit SetRewardAddress(msg.sender,_rewardAddress);
    }

    /**
     * @dev Custom transfer function to burn tokens from users who are not
     * white listed. If a user is white listed a normal transfer occurs.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        super._transfer(sender, recipient, amount);

        // We want to burn tokens if both the sender/recipient aren't whitelisted
        if(whiteList[sender] == false && whiteList[recipient] == false) {
            (uint256 toBurn, uint256 toReward) = calculateFees(amount);
            _burn(recipient, toBurn.add(toReward));
            _mint(rewardAddress, toReward);
        }
    }

    /// @notice Helper function to calcualte the fees which will be deducted from
    /// the transaction
    function calculateFees(uint256 amount) public pure returns (uint256, uint256) {
        uint256 toBurn = amount.mul(BURN_FEE).div(MAX_FEE);
        uint256 toReward = amount.mul(REWARD_FEE).div(MAX_FEE);
        return (toBurn, toReward);
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterGardener).
    function mint(address _to, uint256 _amount) public onlyOwner checkHardCap(_amount) {
        _mint(_to, _amount);
    }

    /// @dev Sets the account to whitelist and not whitelist
    function setWhiteListAccount(address account, bool status) external onlyAdmin() {
        whiteList[account] = status;
        emit WhiteList(account, status);
    }

    /// @dev function to change the `admin` address, can only be done by the address
    function changeAdmin(address _admin) public onlyAdmin() {
        require(admin != address(0), "Admin can't be 0x00000");
        admin = _admin;
    }
}