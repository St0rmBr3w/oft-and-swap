import assert from 'assert'
import MyOFTMock from '../deployments/arbsep/MyOFTMock.json'
import MockERC20 from '../deployments/arbsep/MockERC20.json'

import { type DeployFunction } from 'hardhat-deploy/types'

const contractName = 'SwapMock'

const deploy: DeployFunction = async (hre) => {
    const { getNamedAccounts, deployments } = hre

    const { deploy } = deployments
    const { deployer } = await getNamedAccounts()

    assert(deployer, 'Missing named deployer account')

    const myOFTAddress = MyOFTMock.address // Extracting the address from the JSON
    assert(myOFTAddress, 'MyOFT address not found in JSON file')

    const myERC20Address = MockERC20.address // Extracting the address from the JSON
    assert(myERC20Address, 'MockERC20 address not found in JSON file')

    console.log(`Network: ${hre.network.name}`)
    console.log(`Deployer: ${deployer}`)

    const { address } = await deploy(contractName, {
        from: deployer,
        args: [
            myERC20Address,
        ],
        log: true,
        skipIfAlreadyDeployed: false,
    })

    console.log(`Deployed contract: ${contractName}, network: ${hre.network.name}, address: ${address}`)
}

deploy.tags = [contractName]

export default deploy
