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
