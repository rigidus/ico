async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const balance = await deployer.getBalance();
  console.log("Account balance:", balance.toString());

  const MyICO = await ethers.getContractFactory("MyICO");

  const softCap = ethers.utils.parseEther("10"); // SoftCap 10 ETH
  const hardCap = ethers.utils.parseEther("100"); // HardCap 100 ETH
  const startTime = Math.floor(Date.now() / 1000) + 60; // Начало через 1 минуту
  const endTime = startTime + 86400; // Продолжительность 1 день
  const freezePeriod = 3600; // Freeze период 1 час
  const wallet = "адрес_для_сбора_средств";

  const myICO = await MyICO.deploy(
    softCap,
    hardCap,
    startTime,
    endTime,
    freezePeriod,
    wallet
  );

  await myICO.deployed();

  console.log("MyICO deployed to:", myICO.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
