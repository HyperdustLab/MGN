/** @format */

import { ethers, run, upgrades } from 'hardhat'

async function main() {
  const _HyperAGI_Epoch_Awards = await ethers.getContractFactory('HyperAGI_Epoch_Awards')

  const HyperAGI_Epoch_Awards = await upgrades.upgradeProxy('0x36c08046833F7B2E2E938B0855d3C16F7CF66E96', _HyperAGI_Epoch_Awards)

  // 验证实现合约
  const implementationAddress = await upgrades.erc1967.getImplementationAddress(HyperAGI_Epoch_Awards.target)

  await run('verify:verify', {
    address: implementationAddress,
    constructorArguments: [],
  })
}

// We recommend this pattern to be able to use async/await everywhere q
// and properly handle errors.
main().catch(error => {
  console.error(error)
  process.exitCode = 1
})
