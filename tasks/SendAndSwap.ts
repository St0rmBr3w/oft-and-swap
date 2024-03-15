// Import necessary modules and types from Hardhat and LayerZero libraries.
import { task } from "hardhat/config";
import { TaskArguments } from "hardhat/types";
import SwapMock from '../deployments/arbsep/SwapMock.json' // SwapMock contract information
import { Options } from "@layerzerolabs/lz-v2-utilities"; // LayerZero utilities
import { EndpointId } from "@layerzerolabs/lz-definitions"; // LayerZero endpoint definitions
import { SendParam } from "./typeDefinitions.ts"; // Custom type definitions for the OFT SendParam

// Define a new Hardhat task named 'sendAndSwap'. This task will use the send function of a MyOFTMock contract
// to send tokens and simultaneously encode swap parameters for swapping the token on the destination chain.
task("sendAndSwap", "Calls the send function on the MyOFTMock contract with encoded swap parameters")
    .addParam("contract", "The address of the MyOFTMock contract")
    .addParam("amount", "The amount of MyOFT to send")
    .addParam("recipient", "The recipient address")
    .setAction(async (taskArgs: TaskArguments, { ethers }) => {
        // Attach to the MyOFTMock contract using its address
        const MyOFTMock = await ethers.getContractFactory("MyOFTMock");
        const myOFTMock = MyOFTMock.attach(taskArgs.contract);

        // Encode the amount and recipient address to be used in the compose message.
        // This is necessary for specifying the swap operation on the destination chain.
        const amountToSwap = ethers.utils.parseEther(taskArgs.amount).toBigInt();
        const recipientAddress = taskArgs.recipient;
        const encodedComposeMsg = ethers.utils.defaultAbiCoder.encode(
            ["uint256", "address"], 
            [amountToSwap, recipientAddress]
        );

        // Prepare the parameters for the send operation. This includes details about the destination endpoint,
        // the address of the SwapMock contract (on the destination chain), the amount to send, and the encoded compose message.
        const sendParam: SendParam = {
            dstEid: EndpointId.ARBSEP_V2_TESTNET, // Destination Endpoint ID
            to: ethers.utils.hexZeroPad(SwapMock.address, 32), // Destination address (SwapMock contract)
            amountLD: amountToSwap, // Amount to send
            minAmountLD: amountToSwap, // Minimum amount to send
            extraOptions: Options.newOptions().addExecutorLzReceiveOption(200000, 0).addExecutorComposeOption(0, 50000, 0).toHex().toString(),
            composeMsg: encodedComposeMsg, // The encoded message for swap operation (this should be decoded by the composing contract)
            oftCmd: ethers.utils.arrayify('0x') // Assuming no OFT command is needed
        };

        // Retrieve a quote for the send operation, including any associated fees.
        // The native fee = source chain gas cost + Security Stack fees + Executor fees + destination chain gas cost (i.e., Execution Options)
        const feeQuote = await myOFTMock.quoteSend(sendParam, false);
        const nativeFee = feeQuote.nativeFee;

        // Execute the send transaction. This will transfer the tokens and initiate the swap on the destination chain.
        const tx = await myOFTMock.send(
            sendParam,
            { nativeFee: nativeFee, lzTokenFee: 0 },
            taskArgs.recipient, // _refundAddress
            { value: nativeFee } // Adjust the ETH value as required for the transaction
        );

        // Log the transaction hash and wait for the transaction to be included on the source chain.
        console.log(`✅ LayerZero Tx initiated! See: https://testnet.layerzeroscan.com/tx/${tx.hash}`)
        await tx.wait();
        console.log("sendAndSwap transaction completed.");
    });

export default {};