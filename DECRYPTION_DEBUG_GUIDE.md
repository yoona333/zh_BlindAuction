# 🔍 解密失败诊断指南

## 问题现象

授权成功后,调用 `userDecrypt` 仍然返回空结果:
```
Error: Decryption returned no results
```

## 可能的原因

### 1. Operator 授权未生效 ❌

**症状:**
- `setOperator` 交易已确认
- 但链上实际没有授权记录

**验证方法:**
```typescript
// 在浏览器控制台运行
const provider = new ethers.BrowserProvider(window.ethereum);
const token = new ethers.Contract(
  "0xAE4b8A28B69Ab86fb905Fc535e0F4B27bbe59243",
  ["function isOperator(address owner, address operator) view returns (bool)"],
  provider
);

const userAddr = "你的地址";
const isOp = await token.isOperator(userAddr, userAddr);
console.log("Is operator:", isOp);
```

### 2. Relayer 服务问题 ⚠️

**症状:**
- EIP-712 签名成功
- 调用 `userDecrypt` 后长时间无响应或返回空

**可能原因:**
- Relayer URL 不正确
- Relayer 服务不可用
- 网络连接问题

**验证方法:**
```bash
# 测试 Relayer 连接
curl https://relayer.testnet.zama.org/health
```

### 3. Handle 格式问题 ❓

**症状:**
- Handle 读取正确
- 但解密时 Relayer 无法识别

**检查:**
```
原始 handle: 0x4da1d0e68774171f4aa23a078fe99448845036c3bbff0000000000aa36a70500
转换后: 应该保持相同,长度 66 (0x + 64个字符)
```

### 4. 合约地址不匹配 ❌

**症状:**
- 使用了错误的合约地址

**检查:**
```
Token 合约: 0xAE4b8A28B69Ab86fb905Fc535e0F4B27bbe59243
调用时使用的地址应该完全一致(包括大小写)
```

## 🔧 解决步骤

### 步骤 1: 验证 Operator 状态

在浏览器控制台运行:

```javascript
// 1. 连接合约
const provider = new ethers.BrowserProvider(window.ethereum);
const signer = await provider.getSigner();
const userAddr = await signer.getAddress();

const token = new ethers.Contract(
  "0xAE4b8A28B69Ab86fb905Fc535e0F4B27bbe59243",
  [
    "function isOperator(address owner, address operator) view returns (bool)",
    "function operators(address owner, address operator) view returns (uint256)"
  ],
  provider
);

// 2. 检查是否已授权
const isOp = await token.isOperator(userAddr, userAddr);
console.log("✅ Is operator:", isOp);

// 3. 检查授权过期时间
const expiry = await token.operators(userAddr, userAddr);
const expiryDate = new Date(Number(expiry) * 1000);
console.log("⏰ Expiry:", expiryDate.toISOString());
console.log("⏰ Is expired:", expiryDate < new Date());
```

### 步骤 2: 如果未授权或已过期

```javascript
// 重新授权 (7 天有效期)
const expiry = Math.floor(Date.now() / 1000) + 7 * 86400;
const tx = await token.connect(signer).setOperator(userAddr, expiry);
console.log("📝 Transaction sent:", tx.hash);

const receipt = await tx.wait();
console.log("✅ Transaction confirmed:", receipt.transactionHash);

// 等待 5 秒让状态同步
await new Promise(r => setTimeout(r, 5000));

// 再次验证
const isOpAfter = await token.isOperator(userAddr, userAddr);
console.log("✅ Is operator after approval:", isOpAfter);
```

### 步骤 3: 测试解密

确认已授权后,尝试解密:

```javascript
// 使用你的 FHEVM instance
const handle = BigInt("你的handle"); 
const result = await fhevmInstance.userDecrypt(...);
console.log("Decryption result:", result);
```

## 🎯 快速修复 (临时方案)

如果以上都不行,可以尝试:

### 方案 A: 延长等待时间

修改 `Tokens.tsx`:

```typescript
// 从 5 秒增加到 10 秒
await new Promise(r => setTimeout(r, 10000));
```

### 方案 B: 手动授权后再解密

1. 先单独点击"授权"按钮
2. 等待交易确认
3. 等待 10 秒
4. 再点击"解密"

### 方案 C: 使用 delegatedUserDecrypt

如果 `userDecrypt` 不work,尝试使用委托解密:

```typescript
const result = await instance.delegatedUserDecrypt(
  handleContractPair,
  keypair.privateKey,
  keypair.publicKey,
  signature,
  contractAddress,
  address
);
```

## 📊 已知问题

1. **Sepolia Relayer 响应慢** - 可能需要等待更长时间
2. **EIP-712 domain 参数** - 确保使用正确的 chainId
3. **Gas limit 过高** - 已修复为 200,000

## 🔗 有用的链接

- [Zama Relayer 状态](https://status.zama.ai/)
- [FHEVM 解密文档](https://docs.zama.ai/fhevm/guides/decrypt)
- [Sepolia Etherscan - 查看交易](https://sepolia.etherscan.io/)

---

**建议:** 先在控制台手动验证 `isOperator` 状态,这是最关键的!
