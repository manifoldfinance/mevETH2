const { expect } = require("chai")
const { ethers } = require("hardhat")
const {BigNumber} = require("@ethersproject/bignumber");

describe("OFT v2: ", function () {
    const localChainId = 1
    const remoteChainId = 2
    const name = "OmnichainFungibleToken"
    const symbol = "OFT"
    const sharedDecimals = 8

    let LZEndpointMock, MEVETH, OFTV2, WETH9
    let localEndpoint, remoteEndpoint, localOFT, remoteOFT, erc20, remotePath, localPath, weth
    let owner, alice, bob

    before(async function () {
        LZEndpointMock = await ethers.getContractFactory("LZEndpointMock")
        OFTV2 = await ethers.getContractFactory("OFTV2")
        MEVETH = await ethers.getContractFactory("MevEth")
        WETH9 = await ethers.getContractFactory("WETH9")
        owner = (await ethers.getSigners())[0]
        alice = (await ethers.getSigners())[1]
        bob = (await ethers.getSigners())[2]
    })

    beforeEach(async function () {
        localEndpoint = await LZEndpointMock.deploy(localChainId)
        remoteEndpoint = await LZEndpointMock.deploy(remoteChainId)
        weth = await WETH9.deploy()

        // create two OmnichainFungibleToken instances
        localOFT = await MEVETH.deploy(owner.address, weth.address, localEndpoint.address)
        remoteOFT = await OFTV2.deploy(name, symbol, 18, sharedDecimals, owner.address, remoteEndpoint.address)

        // internal bookkeeping for endpoints (not part of a real deploy, just for this test)
        await localEndpoint.setDestLzEndpoint(remoteOFT.address, remoteEndpoint.address)
        await remoteEndpoint.setDestLzEndpoint(localOFT.address, localEndpoint.address)

        // set each contracts source address so it can send to each other
        remotePath = ethers.utils.solidityPack(["address", "address"], [remoteOFT.address, localOFT.address])
        localPath = ethers.utils.solidityPack(["address", "address"], [localOFT.address, remoteOFT.address])
        await localOFT.setTrustedRemote(remoteChainId, remotePath) // for A, set B
        await remoteOFT.setTrustedRemote(localChainId, localPath) // for B, set A
    })

    it("send tokens from proxy oft and receive them back", async function () {
        const initialAmount =  ethers.utils.parseEther("1.0000000") // 1 ether
        await localOFT.deposit(initialAmount, alice.address, { value: initialAmount})

        // verify alice has tokens and bob has no tokens on remote chain
        expect(await localOFT.balanceOf(alice.address)).to.be.equal(initialAmount)
        expect(await remoteOFT.balanceOf(bob.address)).to.be.equal(0)

        // alice sends tokens to bob on remote chain
        // approve the proxy to swap your tokens
        await localOFT.connect(alice).approve(localOFT.address, initialAmount)

        // swaps token to remote chain
        const bobAddressBytes32 = ethers.utils.defaultAbiCoder.encode(["address"], [bob.address])
        let nativeFee = (await localOFT.estimateSendFee(remoteChainId, bobAddressBytes32, initialAmount, false, "0x")).nativeFee
        await localOFT.connect(alice).sendFrom(
            alice.address,
            remoteChainId,
            bobAddressBytes32,
            initialAmount,
            [alice.address, ethers.constants.AddressZero, "0x"],
            { value: nativeFee }
        )

        // tokens received on the remote chain
        expect(await remoteOFT.totalSupply()).to.equal(initialAmount)
        expect(await remoteOFT.balanceOf(bob.address)).to.be.equal(initialAmount)

        // bob send tokens back to alice from remote chain
        const aliceAddressBytes32 = ethers.utils.defaultAbiCoder.encode(["address"], [alice.address])
        const halfAmount = initialAmount.div(2)
        nativeFee = (await remoteOFT.estimateSendFee(localChainId, aliceAddressBytes32, initialAmount, false, "0x")).nativeFee
        await remoteOFT.connect(bob).sendFrom(
            bob.address,
            localChainId,
            aliceAddressBytes32,
            initialAmount,
            [bob.address, ethers.constants.AddressZero, "0x"],
            { value: nativeFee }
        )

        // half tokens are burned on the remote chain
        expect(await remoteOFT.totalSupply()).to.equal(0)
        expect(await remoteOFT.balanceOf(bob.address)).to.be.equal(0)

        // tokens received on the local chain and unlocked from the proxy
        expect(await localOFT.balanceOf(alice.address)).to.be.equal(initialAmount)
    })

})