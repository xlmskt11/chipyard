package chipyard

import org.chipsalliance.cde.config.{Config}
import freechips.rocketchip.diplomacy.{AsynchronousCrossing}

// ------------------------------
// Configs with RoCC Accelerators
// ------------------------------

// DOC include start: GemminiRocketConfig
class GemminiRocketConfig extends Config(
  // new gemmini.DefaultGemminiConfig(0, 16, 16, 256, 64) ++                            // use Gemmini systolic array GEMM accelerator
  // new gemmini.DefaultGemminiConfig(1, 16, 16, 256, 64) ++                            // use Gemmini systolic array GEMM accelerator
  // new gemmini.DefaultGemminiConfig(2, 16, 16, 256, 64) ++                            // use Gemmini systolic array GEMM accelerator
  // new gemmini.DefaultGemminiConfig(3, 32, 32, 256, 64) ++                            // use Gemmini systolic array GEMM accelerator
  // new freechips.rocketchip.subsystem.WithoutTLMonitors() ++
  new gemmini.MultiDefaultGemminiConfig(16, 16, 128, 64) ++
  new freechips.rocketchip.subsystem.WithNBanks(4) ++
  new freechips.rocketchip.subsystem.WithNBigCores(1) ++
  // new freechips.rocketchip.subsystem.WithInclusiveCache(nWays=2, capacityKB=2048) ++
  // new freechips.rocketchip.subsystem.WithNMemoryChannels(2) ++ 
  new chipyard.config.WithSystemBusWidth(128) ++
  new chipyard.config.AbstractConfig)
// DOC include end: GemminiRocketConfig

class GemminiRocketConfigFiresim128SPAD128ACC1L2cachebank extends Config(
  // new gemmini.DefaultGemminiConfig(0, 16, 16, 256, 64) ++                            // use Gemmini systolic array GEMM accelerator
  // new gemmini.DefaultGemminiConfig(1, 16, 16, 256, 64) ++                            // use Gemmini systolic array GEMM accelerator
  // new gemmini.DefaultGemminiConfig(2, 16, 16, 256, 64) ++                            // use Gemmini systolic array GEMM accelerator
  // new gemmini.DefaultGemminiConfig(3, 32, 32, 256, 64) ++                            // use Gemmini systolic array GEMM accelerator
  // new freechips.rocketchip.subsystem.WithoutTLMonitors() ++
  new gemmini.MultiDefaultGemminiConfig(16, 16, 128, 128, true, gemmini.GemminiConfigs.firesimConfig.copy(num_counter = 16)) ++
  new freechips.rocketchip.subsystem.WithNBanks(1) ++
  new freechips.rocketchip.subsystem.WithNBigCores(1) ++
  // new freechips.rocketchip.subsystem.WithInclusiveCache(nWays=2, capacityKB=2048) ++
  // new freechips.rocketchip.subsystem.WithNMemoryChannels(2) ++ 
  new chipyard.config.WithSystemBusWidth(128) ++
  new chipyard.config.AbstractConfig)

class Gemmini32x32Rocket128SPAD128ACC1L2cachebankConfig extends Config(
  new gemmini.DefaultGemminiConfig(3, 32, 32, 128, 128, true, gemmini.GemminiConfigs.firesimConfig.copy(num_counter = 16)) ++                            // use Gemmini systolic array GEMM accelerator
  new freechips.rocketchip.subsystem.WithNBanks(1) ++
  new freechips.rocketchip.subsystem.WithNBigCores(1) ++
  new chipyard.config.WithSystemBusWidth(128) ++
  new chipyard.config.AbstractConfig)

class GemminiRocketConfigFiresim256SPAD256ACC1L2cachebank extends Config(
  // new gemmini.DefaultGemminiConfig(0, 16, 16, 256, 64) ++                            // use Gemmini systolic array GEMM accelerator
  // new gemmini.DefaultGemminiConfig(1, 16, 16, 256, 64) ++                            // use Gemmini systolic array GEMM accelerator
  // new gemmini.DefaultGemminiConfig(2, 16, 16, 256, 64) ++                            // use Gemmini systolic array GEMM accelerator
  // new gemmini.DefaultGemminiConfig(3, 32, 32, 256, 64) ++                            // use Gemmini systolic array GEMM accelerator
  // new freechips.rocketchip.subsystem.WithoutTLMonitors() ++
  new gemmini.MultiDefaultGemminiConfig(16, 16, 256, 256, true, gemmini.GemminiConfigs.firesimConfig.copy(num_counter = 16)) ++
  new freechips.rocketchip.subsystem.WithNBanks(1) ++
  new freechips.rocketchip.subsystem.WithNBigCores(1) ++
  // new freechips.rocketchip.subsystem.WithInclusiveCache(nWays=2, capacityKB=2048) ++
  // new freechips.rocketchip.subsystem.WithNMemoryChannels(2) ++ 
  new chipyard.config.WithSystemBusWidth(128) ++
  new chipyard.config.AbstractConfig)

class GemminiRocketConfigFiresim512SPAD512ACC1L2cachebank extends Config(
  // new gemmini.DefaultGemminiConfig(0, 16, 16, 256, 64) ++                            // use Gemmini systolic array GEMM accelerator
  // new gemmini.DefaultGemminiConfig(1, 16, 16, 256, 64) ++                            // use Gemmini systolic array GEMM accelerator
  // new gemmini.DefaultGemminiConfig(2, 16, 16, 256, 64) ++                            // use Gemmini systolic array GEMM accelerator
  // new gemmini.DefaultGemminiConfig(3, 32, 32, 256, 64) ++                            // use Gemmini systolic array GEMM accelerator
  // new freechips.rocketchip.subsystem.WithoutTLMonitors() ++
  new gemmini.MultiDefaultGemminiConfig(16, 16, 512, 512, true, gemmini.GemminiConfigs.firesimConfig.copy(num_counter = 16)) ++
  new freechips.rocketchip.subsystem.WithNBanks(1) ++
  new freechips.rocketchip.subsystem.WithNBigCores(1) ++
  // new freechips.rocketchip.subsystem.WithInclusiveCache(nWays=2, capacityKB=2048) ++
  // new freechips.rocketchip.subsystem.WithNMemoryChannels(2) ++ 
  new chipyard.config.WithSystemBusWidth(128) ++
  new chipyard.config.AbstractConfig)

class GemminiRocketConfigFiresim128SPAD128ACC1L2cachebank256BW extends Config(
  // new gemmini.DefaultGemminiConfig(0, 16, 16, 256, 64) ++                            // use Gemmini systolic array GEMM accelerator
  // new gemmini.DefaultGemminiConfig(1, 16, 16, 256, 64) ++                            // use Gemmini systolic array GEMM accelerator
  // new gemmini.DefaultGemminiConfig(2, 16, 16, 256, 64) ++                            // use Gemmini systolic array GEMM accelerator
  // new gemmini.DefaultGemminiConfig(3, 32, 32, 256, 64) ++                            // use Gemmini systolic array GEMM accelerator
  // new freechips.rocketchip.subsystem.WithoutTLMonitors() ++
  new gemmini.MultiDefaultGemminiConfig(16, 16, 128, 128, true, gemmini.GemminiConfigs.firesimConfig.copy(num_counter = 16, dma_buswidth = 256)) ++
  new freechips.rocketchip.subsystem.WithNBanks(1) ++
  new freechips.rocketchip.subsystem.WithNBigCores(1) ++
  // new freechips.rocketchip.subsystem.WithInclusiveCache(nWays=2, capacityKB=2048) ++
  // new freechips.rocketchip.subsystem.WithNMemoryChannels(2) ++ 
  new chipyard.config.WithSystemBusWidth(256) ++
  new chipyard.config.AbstractConfig)

class GemminiRocketConfigFiresim256SPAD256ACC1L2cachebank256BW extends Config(
  // new gemmini.DefaultGemminiConfig(0, 16, 16, 256, 64) ++                            // use Gemmini systolic array GEMM accelerator
  // new gemmini.DefaultGemminiConfig(1, 16, 16, 256, 64) ++                            // use Gemmini systolic array GEMM accelerator
  // new gemmini.DefaultGemminiConfig(2, 16, 16, 256, 64) ++                            // use Gemmini systolic array GEMM accelerator
  // new gemmini.DefaultGemminiConfig(3, 32, 32, 256, 64) ++                            // use Gemmini systolic array GEMM accelerator
  // new freechips.rocketchip.subsystem.WithoutTLMonitors() ++
  new gemmini.MultiDefaultGemminiConfig(16, 16, 256, 256, true, gemmini.GemminiConfigs.firesimConfig.copy(num_counter = 16, dma_buswidth = 256)) ++
  new freechips.rocketchip.subsystem.WithNBanks(1) ++
  new freechips.rocketchip.subsystem.WithNBigCores(1) ++
  // new freechips.rocketchip.subsystem.WithInclusiveCache(nWays=2, capacityKB=2048) ++
  // new freechips.rocketchip.subsystem.WithNMemoryChannels(2) ++ 
  new chipyard.config.WithSystemBusWidth(256) ++
  new chipyard.config.AbstractConfig)

  class GemminiRocketConfigFiresim512SPAD512ACC1L2cachebank256BW extends Config(
  // new gemmini.DefaultGemminiConfig(0, 16, 16, 256, 64) ++                            // use Gemmini systolic array GEMM accelerator
  // new gemmini.DefaultGemminiConfig(1, 16, 16, 256, 64) ++                            // use Gemmini systolic array GEMM accelerator
  // new gemmini.DefaultGemminiConfig(2, 16, 16, 256, 64) ++                            // use Gemmini systolic array GEMM accelerator
  // new gemmini.DefaultGemminiConfig(3, 32, 32, 256, 64) ++                            // use Gemmini systolic array GEMM accelerator
  // new freechips.rocketchip.subsystem.WithoutTLMonitors() ++
  new gemmini.MultiDefaultGemminiConfig(16, 16, 512, 512, true, gemmini.GemminiConfigs.firesimConfig.copy(num_counter = 16, dma_buswidth = 256)) ++
  new freechips.rocketchip.subsystem.WithNBanks(1) ++
  new freechips.rocketchip.subsystem.WithNBigCores(1) ++
  // new freechips.rocketchip.subsystem.WithInclusiveCache(nWays=2, capacityKB=2048) ++
  // new freechips.rocketchip.subsystem.WithNMemoryChannels(2) ++ 
  new chipyard.config.WithSystemBusWidth(256) ++
  new chipyard.config.AbstractConfig)

class GemminiRocketConfigFiresim extends Config(
  // new gemmini.DefaultGemminiConfig(0, 16, 16, 256, 64) ++                            // use Gemmini systolic array GEMM accelerator
  // new gemmini.DefaultGemminiConfig(1, 16, 16, 256, 64) ++                            // use Gemmini systolic array GEMM accelerator
  // new gemmini.DefaultGemminiConfig(2, 16, 16, 256, 64) ++                            // use Gemmini systolic array GEMM accelerator
  // new freechips.rocketchip.subsystem.WithoutTLMonitors() ++
  new gemmini.MultiDefaultGemminiConfig(16, 16, 128, 128, true, gemmini.GemminiConfigs.firesimConfig) ++
  new freechips.rocketchip.subsystem.WithNBanks(4) ++
  new freechips.rocketchip.subsystem.WithNBigCores(1) ++
  // new freechips.rocketchip.subsystem.WithInclusiveCache(nWays=2, capacityKB=2048) ++
  // new freechips.rocketchip.subsystem.WithNMemoryChannels(2) ++ 
  new chipyard.config.WithSystemBusWidth(128) ++
  new chipyard.config.AbstractConfig)
// DOC include end: GemminiRocketConfig

class SingleGemminiW16b16 extends Config(
  new gemmini.DefaultGemminiConfig(3, 16, 16, 64, 32) ++                            // use Gemmini systolic array GEMM accelerator
  new freechips.rocketchip.subsystem.WithNBanks(4) ++
  new freechips.rocketchip.subsystem.WithNBigCores(1) ++
  // new freechips.rocketchip.subsystem.WithInclusiveCache(nWays=2, capacityKB=2048) ++
  // new freechips.rocketchip.subsystem.WithNMemoryChannels(2) ++ 
  new chipyard.config.WithSystemBusWidth(128) ++
  new chipyard.config.AbstractConfig)
// DOC include end: GemminiRocketConfig

class FourGemminiWFourRocket extends Config(
  new gemmini.DefaultGemminiConfig(3, 8, 8, 16, 8) ++                            // use Gemmini systolic array GEMM accelerator
  new freechips.rocketchip.subsystem.WithNBanks(4) ++
  new freechips.rocketchip.subsystem.WithNBigCores(4) ++
  // new freechips.rocketchip.subsystem.WithInclusiveCache(nWays=2, capacityKB=2048) ++
  // new freechips.rocketchip.subsystem.WithNMemoryChannels(2) ++ 
  new chipyard.config.WithSystemBusWidth(128) ++
  new chipyard.config.AbstractConfig)
// DOC include end: GemminiRocketConfig

class FPGemminiRocketConfig extends Config(
  new gemmini.GemminiFP32DefaultConfig ++                         // use FP32Gemmini systolic array GEMM accelerator
  new freechips.rocketchip.subsystem.WithNBigCores(1) ++
  new chipyard.config.WithSystemBusWidth(128) ++
  new chipyard.config.AbstractConfig)

class LeanGemminiRocketConfig extends Config(
  new gemmini.LeanGemminiConfig ++                                 // use Lean Gemmini systolic array GEMM accelerator
  new freechips.rocketchip.subsystem.WithNBigCores(1) ++
  new chipyard.config.WithSystemBusWidth(128) ++
  new chipyard.config.AbstractConfig)

class LeanGemminiPrintfRocketConfig extends Config(
  new gemmini.LeanGemminiPrintfConfig ++                                 // use Lean Gemmini systolic array GEMM accelerator
  new freechips.rocketchip.subsystem.WithNBigCores(1) ++
  new chipyard.config.WithSystemBusWidth(128) ++
  new chipyard.config.AbstractConfig)

class HwachaRocketConfig extends Config(
  new chipyard.config.WithHwachaTest ++
  new hwacha.DefaultHwachaConfig ++                              // use Hwacha vector accelerator
  new freechips.rocketchip.subsystem.WithNBigCores(1) ++
  new chipyard.config.WithSystemBusWidth(128) ++
  new chipyard.config.AbstractConfig)

class MempressRocketConfig extends Config(
  new mempress.WithMemPress ++                                    // use Mempress (memory traffic generation) accelerator
  new chipyard.config.WithExtMemIdBits(7) ++                      // use 7 bits for tl like request id
  new chipyard.config.WithSystemBusWidth(128) ++
  new freechips.rocketchip.subsystem.WithNBanks(8) ++
  new freechips.rocketchip.subsystem.WithInclusiveCache(nWays=16, capacityKB=2048) ++
  new freechips.rocketchip.subsystem.WithNMemoryChannels(4) ++
  new freechips.rocketchip.subsystem.WithNBigCores(1) ++
  new chipyard.config.AbstractConfig)

class HwachaLargeBoomConfig extends Config(
  new chipyard.config.WithHwachaTest ++
  new hwacha.DefaultHwachaConfig ++                              // use Hwacha vector accelerator
  new boom.common.WithNLargeBooms(1) ++
  new chipyard.config.WithSystemBusWidth(128) ++
  new chipyard.config.AbstractConfig)


// Common platform for the three comparison points below. WithInclusiveCache
// must precede WithNBanks so capacityKB is divided across the configured banks;
// all three systems therefore have one 2 MiB, 8-way, 4-bank L2 cache.
class GemminiComparisonSystemConfig extends Config(
  new freechips.rocketchip.subsystem.WithInclusiveCache(
    nWays = 8,
    capacityKB = 2048) ++
  new freechips.rocketchip.subsystem.WithNBanks(4) ++
  new freechips.rocketchip.subsystem.WithNBigCores(1) ++
  new chipyard.config.WithSystemBusWidth(128))

// BF16 fusion moves twice as many bytes as the original INT8 input/output
// path.  Double each shared memory datapath at the same clock while preserving
// four L2 banks and the 64-byte cache line:
//   accelerator/L2 SystemBus: 128 -> 256 bits
//   external DRAM:        1 x 64 -> 2 x 64-bit channels
// Two 64-bit channels provide the requested 2x aggregate DRAM bandwidth and
// remain compatible with Chipyard's 64-bit SimDRAM model.  Cache lines are
// interleaved between the channels by address bit 6.
// This fragment must precede GemminiComparisonSystemConfig so its SystemBus
// override has higher Config precedence.
class GemminiBf16FusionDoubleBandwidthConfig extends Config(
  new chipyard.config.WithSystemBusWidth(256) ++
  new freechips.rocketchip.subsystem.WithNMemoryChannels(2))

// H1: four 16x16 Gemminis. Each Gemmini has one 128-bit DMA lane with 16
// reader slots and 16 writer slots, for four lanes and 64 slots per direction.
class GemminiComparison4x16RocketConfig extends Config(
  new gemmini.MultiDefaultGemminiConfig(
    mesh_rows = 16,
    mesh_cols = 16,
    sp_kB = 128,
    acc_kB = 128) ++
  new GemminiComparisonSystemConfig ++
  new chipyard.config.AbstractConfig)

// H2: the native one-DMA 32x32 Gemmini baseline (32 slots per direction).
class GemminiComparison1x32RocketConfig extends Config(
  new gemmini.DefaultGemminiConfig(
    op_num = 3,
    mesh_rows = 32,
    mesh_cols = 32,
    sp_kb = 128,
    acc_kb = 128) ++
  new GemminiComparisonSystemConfig ++
  new chipyard.config.AbstractConfig)

// H3: one 32x32 Gemmini with four independent 128-bit DMA/TL lanes. Each lane
// has 16 reader and 16 writer slots, matching H1's four-lane/64-slot-per-
// direction frontend while retaining one load/store/execute controller set.
// class GemminiComparison1x32FourDMARocketConfig extends Config(
//   new gemmini.DefaultGemminiConfig(
//     op_num = 3,
//     mesh_rows = 32,
//     mesh_cols = 32,
//     sp_kb = 128,
//     acc_kb = 128,
//     n_dma_engines = 4,
//     max_in_flight_mem_reqs_per_engine = Some(16)) ++
//   new GemminiComparisonSystemConfig ++
//   new chipyard.config.AbstractConfig)

// H1 plus one standalone VPU. The VPU owns its Vector SRAM and
// dedicated TL/TLB DMA path; custom0/funct64 is routed to it while all other
// custom0 commands continue to target Gemmini0.
class GemminiComparison4x16VpuRocketConfig extends Config(
  new vpu.WithVpu(vpu.VpuConfigs.default) ++
  new gemmini.MultiDefaultGemminiConfig(
    mesh_rows = 16,
    mesh_cols = 16,
    sp_kB = 128,
    acc_kB = 128) ++
  new GemminiComparisonSystemConfig ++
  new chipyard.config.AbstractConfig)

// The same system with BF16 Vector SRAM storage and FP32 VPU compute.
class GemminiComparison4x16Bf16VpuRocketConfig extends Config(
  new vpu.WithVpu(vpu.VpuConfigs.bf16Storage) ++
  new gemmini.MultiDefaultGemminiConfig(
    mesh_rows = 16,
    mesh_cols = 16,
    sp_kB = 128,
    acc_kB = 128) ++
  new GemminiComparisonSystemConfig ++
  new chipyard.config.AbstractConfig)

// Fused inference point: four 8x8 BF16-input/FP32-accumulate Gemminis share
// SPAD/ACC. Each Gemmini has one 16-entry DMA/TL/TLB lane (four lanes total),
// and one 16-lane FP32 VPU uses the shared accumulator as its only vector
// memory. SharedExtEntries owns the Gemmini/VPU accumulator dependencies.
class GemminiComparison4x8Bf16FusionVpuRocketConfig extends Config(
  new vpu.WithGemminiVpuFusionAccBanks(4) ++
  new GemminiBf16FusionDoubleBandwidthConfig ++
  new GemminiComparisonSystemConfig ++
  new chipyard.config.AbstractConfig)

// Fair-capacity private-memory comparison for the shared 4x8 point above.
// Four Gemminis each own 64 KiB SPAD with four unsplit banks and 64 KiB ACC
// with four banks split into two sub-banks. The VPU concatenates the four
// private ACCs into one 256 KiB/16-logical-bank/32-physical-bank space, so its
// two 8-element row fragments can be served together in one cycle.
class GemminiComparison4x8Bf16PrivateFusionVpuRocketConfig extends Config(
  new vpu.WithPrivate4x8GemminiVpuFusion ++
  new GemminiBf16FusionDoubleBandwidthConfig ++
  new GemminiComparisonSystemConfig ++
  new chipyard.config.AbstractConfig)

// Bank-only variants of the 4x8 fusion point. Total ACC capacity remains
// 256 KiB; Gemmini and the VPU see the same logical-bank count.
class GemminiComparison4x8Bf16FusionVpuAcc4BankRocketConfig extends Config(
  new vpu.WithGemminiVpuFusionAccBanks(4) ++
  new GemminiBf16FusionDoubleBandwidthConfig ++
  new GemminiComparisonSystemConfig ++
  new chipyard.config.AbstractConfig)

class GemminiComparison4x8Bf16FusionVpuAcc8BankRocketConfig extends Config(
  new vpu.WithGemminiVpuFusionAccBanks(8) ++
  new GemminiBf16FusionDoubleBandwidthConfig ++
  new GemminiComparisonSystemConfig ++
  new chipyard.config.AbstractConfig)

// One physical 16x16 BF16-input/FP32-accumulate Gemmini plus one 16-lane FP32
// VPU. Four independent 16-entry DMA/TL/TLB lanes match the memory-side
// concurrency of the four-Gemmini configuration. This configuration uses the
// same shared-ACC memory and dependency path as the four-way cluster.
class GemminiComparison1x16Bf16FusionVpuRocketConfig extends Config(
  new vpu.WithSingle16x16GemminiVpuFusion ++
  new GemminiBf16FusionDoubleBandwidthConfig ++
  new GemminiComparisonSystemConfig ++
  new chipyard.config.AbstractConfig)
