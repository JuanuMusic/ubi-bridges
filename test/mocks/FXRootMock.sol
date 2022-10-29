// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IFxStateSender} from "@maticnetwork/fx-portal/contracts/tunnel/FxBaseRootTunnel.sol";
contract FXRootMock is IFxStateSender {
    function sendMessageToChild(address _receiver, bytes calldata _data) external {
        
    }
}