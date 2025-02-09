import "@nomicfoundation/hardhat-verify";
import { artifacts, ethers, run } from 'hardhat';
import { StarWarsCharacterListContract } from '../typechain-types';
const StarWarsCharacterList: StarWarsCharacterListContract = artifacts.require('StarWarsCharacterList');

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);

    const args: any[] = []
    const starWarsCharacterList = await StarWarsCharacterList.new(...args);
    console.log("StarWarsCharacterList deployed to:", starWarsCharacterList.address);
    try {

        const result = await run("verify:verify", {
            address: starWarsCharacterList.address,
            constructorArguments: args,
        })

        console.log(result)
    } catch (e: any) {
        console.log(e.message)
    }
    console.log("Deployed contract at:", starWarsCharacterList.address)

}
main().then(() => process.exit(0)).catch((error) => {
    console.error(error);
    process.exit(1);
});