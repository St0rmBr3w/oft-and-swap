// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IOAppCore } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/interfaces/IOAppCore.sol";
import { IOAppComposer } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/interfaces/IOAppComposer.sol";

contract SwapMock is IOAppComposer {
    using SafeERC20 for IERC20;
    IERC20 public erc20;
    IOAppCore public oft;

    event Swapped(address indexed user, address tokenOut, uint256 amount);

    constructor(address _erc20, address _oft) {
        erc20 = IERC20(_erc20);
        oft = IOAppCore(_oft);
    }

    /// @notice Handles incoming composed messages from LayerZero.
    /// @dev Decodes the message payload and updates the state.
    /// @param _oApp The address of the originating OApp.
    /// @param /*_guid*/ The globally unique identifier of the message.
    /// @param _message The encoded message content.
    function lzCompose(
        address _oApp,
        bytes32 /*_guid*/,
        bytes calldata _message,
        address /*Executor*/,
        bytes calldata /*Executor Data*/
    ) external payable override {
        // Decode the payload to get the message, this is how you would encode it on the source chain
        // abi.encode(uint256, address)
        (uint256 _amountToSwap, address _receiver) = abi.decode(_message, (uint256, address));
        erc20.safeTransferFrom(address(this), _receiver, _amountToSwap);
        emit Swapped(_receiver, address(erc20), _amountToSwap);
    }
}
