import { task } from "hardhat/config";
import { TaskArguments } from "hardhat/types";
import SwapMock from '../deployments/arbsep/SwapMock.json'
import { Options } from "@layerzerolabs/lz-v2-utilities";
import { EndpointId } from "@layerzerolabs/lz-definitions";
import { SendParam } from "./typeDefinitions";

task("send", "Calls the send function on the MyOFTMock contract with encoded swap parameters")
    .addParam("contract", "The address of the MyOFTMock contract")
    .addParam("amount", "The amount of MyOFT to send")
    .addParam("recipient", "The recipient address")
    .setAction(async (taskArgs: TaskArguments, { ethers }) => {
        const MyOFTMock = await ethers.getContractFactory("MyOFTMock");
        const myOFTMock = MyOFTMock.attach(taskArgs.contract);

        // Encoding the uint256 amount and address for the compose message
        const amountToSwap = ethers.utils.parseEther(taskArgs.amount).toBigInt();

        const sendParam: SendParam = {
            dstEid: EndpointId.ARBSEP_V2_TESTNET,
            to: ethers.utils.hexZeroPad(taskArgs.recipient, 32),
            amountLD: amountToSwap,
            minAmountLD: amountToSwap,
            extraOptions: Options.newOptions().addExecutorLzReceiveOption(200000, 0).toHex().toString(),
            composeMsg: ethers.utils.arrayify('0x'), // Assuming no composed message
            oftCmd: ethers.utils.arrayify('0x') // Assuming no OFT command is needed
        };

        // Get the quote for the send operation
        const feeQuote = await myOFTMock.quoteSend(sendParam, false);
        const nativeFee = feeQuote.nativeFee;

        // Sending the transaction
        const tx = await myOFTMock.send(
            sendParam,
            { nativeFee: nativeFee, lzTokenFee: 0 },
            taskArgs.recipient, // _refundAddress
            { value: nativeFee } // Adjust the ETH value as required for the transaction
        );

        console.log("Transaction Hash:", tx.hash);
        await tx.wait();
        console.log("Send transaction completed.");
    });

export default {};