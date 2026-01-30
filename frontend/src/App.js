import { useState } from "react";
import { ethers } from "ethers";

import ERC20ABI from "./abi/ERC20.json";
import RouterABI from "./abi/SwapRouter.json";
import SwapABI from "./abi/LeoGiaSwap.json";

import {
  LEO_ADDRESS,
  GIA_ADDRESS,
  ROUTER_ADDRESS,
  SWAP_ADDRESS
} from "./config";

function App() {
  const [account, setAccount] = useState(null);
  const [provider, setProvider] = useState(null);

  const [leoBalance, setLeoBalance] = useState("0");
  const [giaBalance, setGiaBalance] = useState("0");

  const [leoReserve, setLeoReserve] = useState("0");
  const [giaReserve, setGiaReserve] = useState("0");

  const [amount, setAmount] = useState("");
  const [expectedOut, setExpectedOut] = useState("0");
  const [slippage, setSlippage] = useState(2);
  const [direction, setDirection] = useState("LEO_TO_GIA");

  const [needsApproval, setNeedsApproval] = useState(true);
  const [swaps, setSwaps] = useState([]);
  const [loading, setLoading] = useState(false);
  const [status, setStatus] = useState("");

  /* ---------------- Wallet ---------------- */

  async function connectWallet() {
    const p = new ethers.BrowserProvider(window.ethereum);
    await p.send("eth_requestAccounts", []);
    const signer = await p.getSigner();
    const address = await signer.getAddress();

    setAccount(address);
    setProvider(p);

    await loadBalances(p, address);
    await loadReserves(p);
    await loadSwapHistory(p);
  }

  async function loadBalances(provider, address) {
    const leo = new ethers.Contract(LEO_ADDRESS, ERC20ABI, provider);
    const gia = new ethers.Contract(GIA_ADDRESS, ERC20ABI, provider);

    setLeoBalance(ethers.formatEther(await leo.balanceOf(address)));
    setGiaBalance(ethers.formatEther(await gia.balanceOf(address)));
  }

  async function loadReserves(provider) {
    const swap = new ethers.Contract(SWAP_ADDRESS, SwapABI, provider);
    setLeoReserve(ethers.formatEther(await swap.leoReserve()));
    setGiaReserve(ethers.formatEther(await swap.giaReserve()));
  }

  async function checkAllowance(value) {
    if (!value || !provider) return;

    const signer = await provider.getSigner();
    const token =
      direction === "LEO_TO_GIA"
        ? new ethers.Contract(LEO_ADDRESS, ERC20ABI, signer)
        : new ethers.Contract(GIA_ADDRESS, ERC20ABI, signer);

    const allowance = await token.allowance(account, ROUTER_ADDRESS);
    setNeedsApproval(allowance < ethers.parseEther(value));
  }

  async function approveToken() {
    setStatus("Waiting for approval…");
    try {
      const signer = await provider.getSigner();
      const token =
        direction === "LEO_TO_GIA"
          ? new ethers.Contract(LEO_ADDRESS, ERC20ABI, signer)
          : new ethers.Contract(GIA_ADDRESS, ERC20ABI, signer);

      const tx = await token.approve(
        ROUTER_ADDRESS,
        ethers.MaxUint256
      );
      await tx.wait();

      setNeedsApproval(false);
      setStatus("Approved successfully ✅");
    } catch (err) {
      if (err?.code === 4001) setStatus("Approval cancelled");
      else setStatus("Approval failed");
    }
  }

  function calculateExpectedOut(value) {
    if (!value || Number(value) <= 0) {
      setExpectedOut("0");
      return;
    }

    const reserveIn =
      direction === "LEO_TO_GIA"
        ? Number(leoReserve)
        : Number(giaReserve);

    const reserveOut =
      direction === "LEO_TO_GIA"
        ? Number(giaReserve)
        : Number(leoReserve);

    const amountInWithFee = Number(value) * 0.997;

    const out =
      (amountInWithFee * reserveOut) /
      (reserveIn + amountInWithFee);

    setExpectedOut(out.toFixed(6));
  }

  async function executeSwap() {
    if (!amount) return;

    setLoading(true);
    setStatus("Confirm swap in wallet…");

    try {
      const signer = await provider.getSigner();
      const router = new ethers.Contract(
        ROUTER_ADDRESS,
        RouterABI,
        signer
      );

      const swapFn =
        direction === "LEO_TO_GIA"
          ? router.swapLeoForGia
          : router.swapGiaForLeo;

      const minOut = ethers.parseEther(
        (
          Number(expectedOut) *
          (1 - (slippage + 0.5) / 100)
        ).toString()
      );

      const tx = await swapFn(
        ethers.parseEther(amount),
        minOut,
        { gasLimit: 300000 }
      );

      setStatus("Swapping…");
      await tx.wait();

      setStatus("Swap successful 🎉");

      await loadBalances(provider, account);
      await loadReserves(provider);
      await loadSwapHistory(provider);

      setAmount("");
      setExpectedOut("0");
    } catch (err) {
      if (err?.code === 4001) setStatus("Swap cancelled");
      else setStatus("Swap failed");
    } finally {
      setLoading(false);
    }
  }

  async function loadSwapHistory(provider) {
    const swap = new ethers.Contract(SWAP_ADDRESS, SwapABI, provider);
    const latest = await provider.getBlockNumber();

    const events = [
      ...(await swap.queryFilter("LeoToGiaSwap", latest - 10000, latest)),
      ...(await swap.queryFilter("GiaToLeoSwap", latest - 10000, latest))
    ];

    setSwaps(
      events
        .map(e => ({
          text:
            e.eventName === "LeoToGiaSwap"
              ? `LEO → GIA · ${ethers.formatEther(e.args.leoIn)} → ${ethers.formatEther(e.args.giaOut)}`
              : `GIA → LEO · ${ethers.formatEther(e.args.giaIn)} → ${ethers.formatEther(e.args.leoOut)}`,
          block: e.blockNumber
        }))
        .sort((a, b) => b.block - a.block)
        .slice(0, 6)
    );
  }

  return (
    <div style={{
      minHeight: "100vh",
      display: "flex",
      justifyContent: "center",
      alignItems: "center"
    }}>
      <div className="glass" style={{
        width: 420,
        padding: 28,
        borderRadius: 22,
        boxShadow: "0 20px 40px rgba(0,0,0,0.1)"
      }}>
        <h2 style={{ textAlign: "center", marginBottom: 24 }}>
          LEO ↔ GIA Swap
        </h2>

        {!account ? (
          <button
            onClick={connectWallet}
            style={{
              width: "100%",
              padding: 16,
              background: "#6366f1",
              color: "#fff",
              fontSize: 16
            }}
          >
            Connect Wallet
          </button>
        ) : (
          <>
            <div style={{ fontSize: 13, marginBottom: 12, color: "#475569" }}>
              {account.slice(0, 6)}…{account.slice(-4)}
            </div>

            <div style={{ fontSize: 14, marginBottom: 16 }}>
              <div>🦁 LEO: <b>{leoBalance}</b></div>
              <div>🪙 GIA: <b>{giaBalance}</b></div>
            </div>

            <select
              value={direction}
              onChange={e => {
                setDirection(e.target.value);
                calculateExpectedOut(amount);
                checkAllowance(amount);
              }}
            >
              <option value="LEO_TO_GIA">LEO → GIA</option>
              <option value="GIA_TO_LEO">GIA → LEO</option>
            </select>

            <input
              placeholder="Amount"
              value={amount}
              onChange={e => {
                setAmount(e.target.value);
                calculateExpectedOut(e.target.value);
                checkAllowance(e.target.value);
              }}
              style={{ marginTop: 10 }}
            />

            <div style={{ marginTop: 10, fontSize: 14 }}>
              Expected output: <b>{expectedOut}</b>
            </div>

            <div style={{ marginTop: 16 }}>
              <div style={{ fontSize: 13 }}>
                Slippage: <b>{slippage}%</b>
              </div>
              <input
                type="range"
                min="1"
                max="5"
                step="0.5"
                value={slippage}
                onChange={e => setSlippage(e.target.value)}
              />
            </div>

            {needsApproval ? (
              <button
                onClick={approveToken}
                style={{
                  marginTop: 18,
                  width: "100%",
                  padding: 16,
                  background: "#2563eb",
                  color: "#fff"
                }}
              >
                Approve
              </button>
            ) : (
              <button
                onClick={executeSwap}
                disabled={loading}
                style={{
                  marginTop: 18,
                  width: "100%",
                  padding: 16,
                  background: loading ? "#94a3b8" : "#16a34a",
                  color: "#fff"
                }}
              >
                {loading ? "Processing…" : "Swap"}
              </button>
            )}

            {status && (
              <div style={{
                marginTop: 14,
                fontSize: 13,
                textAlign: "center",
                color: status.includes("failed") ? "#dc2626" : "#334155"
              }}>
                {status}
              </div>
            )}

            <div style={{ marginTop: 28 }}>
              <h4 style={{ marginBottom: 8 }}>Recent Swaps</h4>
              {swaps.map((s, i) => (
                <div
                  key={i}
                  style={{
                    fontSize: 13,
                    padding: "6px 0",
                    borderBottom: "1px solid #e5e7eb"
                  }}
                >
                  {s.text}
                </div>
              ))}
            </div>
          </>
        )}
      </div>
    </div>
  );
}

export default App;
