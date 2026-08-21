#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "${SCRIPT_DIR}/.." && pwd)

GEMMINI_TESTS="${REPO_ROOT}/sims/firesim/target-design/chipyard/generators/gemmini/software/gemmini-rocc-tests"
GEMMINI_PARAMS="${GEMMINI_TESTS}/include/gemmini_params.h"
FIREMARSHAL_DIR="${REPO_ROOT}/sims/firesim/sw/firesim-software"
BR_BASE_IMAGE_DIR="${FIREMARSHAL_DIR}/images/firechip/br-base"
WORKLOAD_DIR="${REPO_ROOT}/sims/firesim/deploy/workloads/gemmini-uniform"
DEPLOY_DIR="${REPO_ROOT}/sims/firesim/deploy"
RESULTS_DIR="${DEPLOY_DIR}/results-workload"

RUN_MODE="${RUN_MODE:-fixed}"
if [[ "${RUN_MODE}" == "llama_shape_single32" ]]; then
  REMOTE_SSH="${REMOTE_SSH:-dwc06209@165.132.142.249}"
  REMOTE_PORT="${REMOTE_PORT:-22}"
  REMOTE_SIM_DIR="${REMOTE_SIM_DIR:-/home/dwc06209/FIRESIM_RUNS_DIR}"
else
  REMOTE_SSH="${REMOTE_SSH:-dwc06209@165.132.140.144}"
  REMOTE_PORT="${REMOTE_PORT:-4121}"
  REMOTE_SIM_DIR="${REMOTE_SIM_DIR:-/data/dwc06209/FIRESIM_RUNS_DIR}"
fi
SCREEN_NAME="${SCREEN_NAME:-fsim0}"
BOOT_TIMEOUT_SECONDS="${BOOT_TIMEOUT_SECONDS:-600}"
STALL_TIMEOUT_SECONDS="${STALL_TIMEOUT_SECONDS:-1800}"
MONITOR_POLL_SECONDS="${MONITOR_POLL_SECONDS:-30}"
RUNWORKLOAD_TIMEOUT_SECONDS="${RUNWORKLOAD_TIMEOUT_SECONDS:-0}"
REMOTE_SCREEN_EXIT_TIMEOUT_SECONDS="${REMOTE_SCREEN_EXIT_TIMEOUT_SECONDS:-60}"
KILL_STALE_REMOTE_SCREEN="${KILL_STALE_REMOTE_SCREEN:-0}"
RUN_INIT_SUBMODULES="${RUN_INIT_SUBMODULES:-1}"
RESULT_COPY_DIR="${RESULT_COPY_DIR:-${RESULTS_DIR}/${RUN_MODE}_tiling_automation}"
LLAMA_PACKING_MODES="${LLAMA_PACKING_MODES:-000 001 010 011 100 101 110 111}"
LLAMA_GEMMINI_COUNTS="${LLAMA_GEMMINI_COUNTS:-1 2 3 4}"
LLAMA_CHECK="${LLAMA_CHECK:-false}"
LLAMA_FIXED_TILE_I="${LLAMA_FIXED_TILE_I:-}"
LLAMA_FIXED_TILE_J="${LLAMA_FIXED_TILE_J:-}"
LLAMA_FIXED_TILE_K="${LLAMA_FIXED_TILE_K:-}"
LLAMA_SINGLE32_GEMMINI_CONFIGURATION="${LLAMA_SINGLE32_GEMMINI_CONFIGURATION:-0x8}"
LLAMA_HUGEPAGE_LOG2="${LLAMA_HUGEPAGE_LOG2:-21}"

DEFAULT_SHAPES=(
  "192x512x2048"
  "192x2048x2048"
  "192x2048x8192"
  "192x8192x2048"
  "208x512x2048"
  "208x2048x2048"
  "208x2048x8192"
  "208x8192x2048"
  "224x512x2048"
  "224x2048x2048"
  "224x2048x8192"
  "224x8192x2048"
  "240x512x2048"
  "240x2048x2048"
  "240x2048x8192"
  "240x8192x2048"
  "256x512x2048"
  "256x2048x2048"
  "256x2048x8192"
  "256x8192x2048"
)

LLAMA_DEFAULT_SHAPES=(
  "128x512x2048"
  "128x2048x2048"
  "128x2048x8192"
  "128x8192x2048"
)

LLAMA_SINGLE32_DEFAULT_SHAPES=(
  "192x512x2048"
  "192x2048x2048"
  "192x2048x8192"
  "192x8192x2048"
)

SWEEP_BUILD_TARGETS=(
  "tiling_swap_test_1gem-linux"
  "tiling_swap_test_2gem-linux"
  "tiling_swap_test_3gem-linux"
  "tiling_swap_test-linux"
)

SWEEP_GUEST_TESTS=(
  "tiling_swap_test_1gem"
  "tiling_swap_test_2gem"
  "tiling_swap_test_3gem"
  "tiling_swap_test_4gem"
)

FIXED_BUILD_TARGETS=(
  "fixed_tiling_matmul_test_1gem-linux"
  "fixed_tiling_matmul_test_2gem-linux"
  "fixed_tiling_matmul_test_3gem-linux"
  "fixed_tiling_matmul_test_4gem-linux"
)

FIXED_GUEST_TESTS=(
  "fixed_tiling_matmul_test_1gem"
  "fixed_tiling_matmul_test_2gem"
  "fixed_tiling_matmul_test_3gem"
  "fixed_tiling_matmul_test_4gem"
)

LLAMA_BUILD_TARGETS=()
LLAMA_GUEST_TESTS=()
LLAMA_TEST_PAGE_PACKED=()
LLAMA_TEST_A_PACKED=()
LLAMA_TEST_B_PACKED=()
LLAMA_TEST_C_PACKED=()
LLAMA_TEST_D_PACKED=()
LLAMA_TEST_GEMMINI_COUNT=()
LLAMA_TEST_MULTI=()
LLAMA_TEST_USE_HUGEPAGE=()
LLAMA_TEST_HUGEPAGE_LOG2=()

BUILD_TARGETS=()
GUEST_TESTS=()

LLAMA_SUMMARY_HEADER='shape,attempt,outcome,test_name,page_packed,a_packed,b_packed,c_packed,d_packed,gemmini_count,gemmini_configuration,mat_dim_i,mat_dim_j,mat_dim_k,tile_i,tile_j,tile_k,weight_cache_prepare_cycles,activation_quantization_cycles,gemmini_job_setup_cycles,gemmini_matmul_cycles,output_dequantization_cycles,total_cycles,matmul_mode,use_hugepage,vm_page_bytes,hugepages_requested,hugepages_reserved,hugepage_reservation_status,rdma_tlb_wait_cycles_sum,rdma_tl_wait_cycles_sum,rdma_bytes_rec_sum,rdma_total_latency_sum,wdma_tlb_wait_cycles_sum,wdma_tl_wait_cycles_sum,wdma_bytes_sent_sum,wdma_total_latency_sum,dma_tlb_total_req_sum,dma_tlb_hit_req_sum,dma_tlb_miss_req_sum,dma_tlb_miss_cycle_sum,rdma_active_cycle_sum,wdma_active_cycle_sum,load_dma_wait_cycle_sum,store_dma_wait_cycle_sum,load_active_cycle_sum'

runworkload_pid=""
init_submodules_done=0
NEXT_TEST_INDEX=0
NEXT_START_I=1
NEXT_START_J=1
NEXT_START_K=1

log() {
  printf '[%s] %s\n' "$(date '+%F %T')" "$*"
}

quote() {
  printf '%q' "$1"
}

ssh_cmd() {
  ssh -o StrictHostKeyChecking=no -p "${REMOTE_PORT}" "${REMOTE_SSH}" "$@"
}

remote_uart_path() {
  printf '%s/sim_slot_0/uartlog' "${REMOTE_SIM_DIR}"
}

cleanup() {
  if [[ -n "${runworkload_pid}" ]] && kill -0 "${runworkload_pid}" 2>/dev/null; then
    log "Stopping local firesim runworkload process ${runworkload_pid}"
    kill -INT "${runworkload_pid}" 2>/dev/null || true
    wait "${runworkload_pid}" 2>/dev/null || true
  fi
}
trap cleanup EXIT

usage() {
  cat <<'EOF'
Usage:
  scripts/run-tiling-swap-firesim.sh [IxJxK ...]

Default fixed sweep:
  P in 192 208 224 240 256
  shapes Px512x2048 Px2048x2048 Px2048x8192 Px8192x2048
  gemmini counts 1 2 3 4
  fixed tiles selected from the prompt/configuration table

Single 32-DIM VM-page comparison:
  RUN_MODE=llama_shape_single32 scripts/run-tiling-swap-firesim.sh
  Runs 192x{512x2048,2048x2048,2048x8192,8192x2048}
  Tests 4 KiB A0B0C0, 4 KiB A1B1C1, and 2 MiB A0B0C0

Environment overrides:
  RUN_MODE=fixed                     # fixed, sweep, llama_shape, or llama_shape_single32
  REMOTE_SSH/REMOTE_PORT/REMOTE_SIM_DIR # U250 defaults in llama_shape_single32; U280 otherwise
  SCREEN_NAME=fsim0
  BOOT_TIMEOUT_SECONDS=600
  STALL_TIMEOUT_SECONDS=1800      # 30 minutes without UART updates
  MONITOR_POLL_SECONDS=30
  RUNWORKLOAD_TIMEOUT_SECONDS=0   # 0 means no timeout
  REMOTE_SCREEN_EXIT_TIMEOUT_SECONDS=60
  KILL_STALE_REMOTE_SCREEN=0      # set 1 to kill stale remote screen before starting an attempt
  RUN_INIT_SUBMODULES=1           # set 0 to skip ./init-submodules.sh
  RESULT_COPY_DIR=sims/firesim/deploy/results-workload/${RUN_MODE}_tiling_automation
  LLAMA_PACKING_MODES="000 001 010 011 100 101 110 111" # A/B/C packed bits, only for RUN_MODE=llama_shape
  LLAMA_GEMMINI_COUNTS="1 2 3 4"   # only for RUN_MODE=llama_shape
  LLAMA_CHECK=false                # pass -DCHECK=false by default
  LLAMA_FIXED_TILE_I/J/K=          # optional override; single32 default 4,4,8, llama_shape default 8,8,16 (3gem I=6)
  LLAMA_SINGLE32_GEMMINI_CONFIGURATION=0x8 # custom3 on the single 32-DIM hardware
  LLAMA_HUGEPAGE_LOG2=21           # 2 MiB HugeTLB page for llama_shape_single32
EOF
}

is_llama_run_mode() {
  [[ "${RUN_MODE}" == "llama_shape" ||
     "${RUN_MODE}" == "llama_shape_single32" ]]
}

configure_run_mode() {
  case "${RUN_MODE}" in
    fixed)
      BUILD_TARGETS=("${FIXED_BUILD_TARGETS[@]}")
      GUEST_TESTS=("${FIXED_GUEST_TESTS[@]}")
      ;;
    sweep)
      BUILD_TARGETS=("${SWEEP_BUILD_TARGETS[@]}")
      GUEST_TESTS=("${SWEEP_GUEST_TESTS[@]}")
      ;;
    llama_shape)
      configure_llama_shape_tests
      BUILD_TARGETS=("${LLAMA_BUILD_TARGETS[@]}")
      GUEST_TESTS=("${LLAMA_GUEST_TESTS[@]}")
      ;;
    llama_shape_single32)
      configure_llama_single32_tests
      BUILD_TARGETS=("${LLAMA_BUILD_TARGETS[@]}")
      GUEST_TESTS=("${LLAMA_GUEST_TESTS[@]}")
      ;;
    *)
      printf 'Invalid RUN_MODE "%s"; expected fixed, sweep, llama_shape, or llama_shape_single32\n' "${RUN_MODE}" >&2
      return 1
      ;;
  esac
}

parse_shape() {
  local shape=${1//X/x}
  IFS=x read -r MAT_I MAT_J MAT_K extra <<< "${shape}"

  if [[ -n "${extra:-}" ||
        ! "${MAT_I}" =~ ^[0-9]+$ ||
        ! "${MAT_J}" =~ ^[0-9]+$ ||
        ! "${MAT_K}" =~ ^[0-9]+$ ]]; then
    printf 'Invalid shape "%s"; expected IxJxK, for example 104x2048x2048\n' "$1" >&2
    return 1
  fi
}

gemmini_dim() {
  awk '/^#define[[:space:]]+DIM[[:space:]]+[0-9]+/ { print $3; exit }' "${GEMMINI_PARAMS}"
}

fixed_gemmini_configuration_for_test_index() {
  case "$1" in
    0) printf '0x1\n' ;;
    1) printf '0x3\n' ;;
    2) printf '0x7\n' ;;
    3) printf '0xf\n' ;;
    *)
      printf 'Invalid fixed test index %s\n' "$1" >&2
      return 1
      ;;
  esac
}

gemmini_configuration_for_count() {
  case "$1" in
    1) printf '0x1\n' ;;
    2) printf '0x3\n' ;;
    3) printf '0x7\n' ;;
    4) printf '0xf\n' ;;
    *)
      printf 'Invalid Gemmini count %s; expected 1, 2, 3, or 4\n' "$1" >&2
      return 1
      ;;
  esac
}

llama_tile_for_gemmini_count() {
  local count=$1

  if [[ -n "${LLAMA_FIXED_TILE_I}" ||
        -n "${LLAMA_FIXED_TILE_J}" ||
        -n "${LLAMA_FIXED_TILE_K}" ]]; then
    if [[ ! "${LLAMA_FIXED_TILE_I}" =~ ^[0-9]+$ ||
          ! "${LLAMA_FIXED_TILE_J}" =~ ^[0-9]+$ ||
          ! "${LLAMA_FIXED_TILE_K}" =~ ^[0-9]+$ ]]; then
      printf 'LLAMA_FIXED_TILE_I/J/K must all be set to positive integers when overriding tile size\n' >&2
      return 1
    fi
    printf '%s %s %s\n' "${LLAMA_FIXED_TILE_I}" "${LLAMA_FIXED_TILE_J}" "${LLAMA_FIXED_TILE_K}"
    return
  fi

  if [[ "${RUN_MODE}" == "llama_shape_single32" ]]; then
    printf '4 4 8\n'
    return
  fi

  if [[ "${count}" == "3" ]]; then
    printf '6 8 16\n'
  else
    printf '8 8 16\n'
  fi
}

configure_llama_shape_tests() {
  local mode
  local packed
  local a_packed
  local b_packed
  local c_packed
  local d_packed
  local count
  local label
  local target
  local guest

  LLAMA_BUILD_TARGETS=()
  LLAMA_GUEST_TESTS=()
  LLAMA_TEST_PAGE_PACKED=()
  LLAMA_TEST_A_PACKED=()
  LLAMA_TEST_B_PACKED=()
  LLAMA_TEST_C_PACKED=()
  LLAMA_TEST_D_PACKED=()
  LLAMA_TEST_GEMMINI_COUNT=()
  LLAMA_TEST_MULTI=()
  LLAMA_TEST_USE_HUGEPAGE=()
  LLAMA_TEST_HUGEPAGE_LOG2=()

  for mode in ${LLAMA_PACKING_MODES}; do
    if ! [[ "${mode}" =~ ^[01][01][01]$ ]]; then
      printf 'Invalid LLAMA_PACKING_MODES entry "%s"; expected three bits like 011 for A/B/C\n' "${mode}" >&2
      return 1
    fi

    a_packed="${mode:0:1}"
    b_packed="${mode:1:1}"
    c_packed="${mode:2:1}"
    d_packed=0
    packed=0
    if [[ "${a_packed}" == "1" || "${b_packed}" == "1" || "${c_packed}" == "1" ]]; then
      packed=1
    fi
    label="a${a_packed}b${b_packed}c${c_packed}"

    for count in ${LLAMA_GEMMINI_COUNTS}; do
      gemmini_configuration_for_count "${count}" >/dev/null
      target="llama_shape_test_${label}_${count}gem-linux"
      guest="llama_shape_test_${label}_${count}gem"
      LLAMA_BUILD_TARGETS+=("${target}")
      LLAMA_GUEST_TESTS+=("${guest}")
      LLAMA_TEST_PAGE_PACKED+=("${packed}")
      LLAMA_TEST_A_PACKED+=("${a_packed}")
      LLAMA_TEST_B_PACKED+=("${b_packed}")
      LLAMA_TEST_C_PACKED+=("${c_packed}")
      LLAMA_TEST_D_PACKED+=("${d_packed}")
      LLAMA_TEST_GEMMINI_COUNT+=("${count}")
      LLAMA_TEST_MULTI+=(1)
      LLAMA_TEST_USE_HUGEPAGE+=(0)
      LLAMA_TEST_HUGEPAGE_LOG2+=("${LLAMA_HUGEPAGE_LOG2}")
    done
  done
}

configure_llama_single32_tests() {
  local dim
  local runtime_config="${DEPLOY_DIR}/config_runtime.yaml"
  local hw_config

  dim=$(gemmini_dim)
  if [[ "${dim}" != "32" ]]; then
    printf 'RUN_MODE=llama_shape_single32 requires DIM=32 in %s; found "%s"\n' \
      "${GEMMINI_PARAMS}" "${dim:-unknown}" >&2
    return 1
  fi

  hw_config=$(awk '/^[[:space:]]*default_hw_config:/ { print $2; exit }' \
    "${runtime_config}")
  if [[ "${hw_config}" != *singlegemmini32x32* ]]; then
    printf 'RUN_MODE=llama_shape_single32 requires a single-Gemmini 32x32 default_hw_config in %s; found "%s"\n' \
      "${runtime_config}" "${hw_config:-unknown}" >&2
    return 1
  fi

  case "${LLAMA_SINGLE32_GEMMINI_CONFIGURATION}" in
    1|2|4|8|0x1|0x2|0x4|0x8) ;;
    *)
      printf 'LLAMA_SINGLE32_GEMMINI_CONFIGURATION must select exactly one custom slot; got "%s"\n' \
        "${LLAMA_SINGLE32_GEMMINI_CONFIGURATION}" >&2
      return 1
      ;;
  esac

  if [[ "${LLAMA_HUGEPAGE_LOG2}" != "21" ]]; then
    printf 'RUN_MODE=llama_shape_single32 currently requires LLAMA_HUGEPAGE_LOG2=21 for the 2 MiB comparison\n' >&2
    return 1
  fi

  LLAMA_BUILD_TARGETS=(
    "llama_shape_test_a0b0c0_1gem-linux"
    "llama_shape_test_a1b1c1_1gem-linux"
    "llama_shape_test_2m_a0b0c0_1gem-linux"
  )
  LLAMA_GUEST_TESTS=(
    "llama_shape_test_a0b0c0_1gem"
    "llama_shape_test_a1b1c1_1gem"
    "llama_shape_test_2m_a0b0c0_1gem"
  )
  LLAMA_TEST_PAGE_PACKED=(0 1 0)
  LLAMA_TEST_A_PACKED=(0 1 0)
  LLAMA_TEST_B_PACKED=(0 1 0)
  LLAMA_TEST_C_PACKED=(0 1 0)
  LLAMA_TEST_D_PACKED=(0 0 0)
  LLAMA_TEST_GEMMINI_COUNT=(1 1 1)
  LLAMA_TEST_MULTI=(0 0 0)
  LLAMA_TEST_USE_HUGEPAGE=(0 0 1)
  LLAMA_TEST_HUGEPAGE_LOG2=(21 21 21)
}

fixed_tile_for_test_index() {
  local shape=$1
  local test_index=$2
  parse_shape "${shape}"

  case "${MAT_J}x${MAT_K}" in
    512x2048|2048x2048|2048x8192|8192x2048) ;;
    *)
      printf 'No fixed tile table entry for shape "%s"\n' "${shape}" >&2
      return 1
      ;;
  esac

  case "${MAT_I}:${test_index}" in
    192:0) printf '8 8 16\n' ;;
    192:1) printf '8 8 16\n' ;;
    192:2) printf '6 8 16\n' ;;
    192:3) printf '8 8 16\n' ;;
    208:0) printf '8 8 16\n' ;;
    208:1) printf '8 8 16\n' ;;
    208:2) printf '6 8 16\n' ;;
    208:3) printf '8 8 16\n' ;;
    224:0) printf '8 8 16\n' ;;
    224:1) printf '8 8 16\n' ;;
    224:2) printf '6 8 16\n' ;;
    224:3) printf '8 8 16\n' ;;
    240:0) printf '8 8 16\n' ;;
    240:1) printf '8 8 16\n' ;;
    240:2) printf '6 8 16\n' ;;
    240:3) printf '8 8 16\n' ;;
    256:0) printf '8 8 16\n' ;;
    256:1) printf '8 8 16\n' ;;
    256:2) printf '6 8 16\n' ;;
    256:3) printf '8 8 16\n' ;;
    *)
      printf 'No fixed tile table entry for prompt/test index "%s:%s"\n' "${MAT_I}" "${test_index}" >&2
      return 1
      ;;
  esac
}

require_linux_compiler() {
  if command -v riscv64-unknown-linux-gnu-gcc >/dev/null ||
     command -v riscv64-linux-gnu-gcc >/dev/null; then
    return
  fi

  cat >&2 <<'EOF'
Could not find a RISC-V Linux compiler in PATH.
Run this script from the same environment where gemmini-rocc-tests ./build.sh can build Linux binaries.
Typical setup is to source the Chipyard/FireSim environment first.
EOF
  return 1
}

ensure_build_configured() {
  if [[ -f "${GEMMINI_TESTS}/build/Makefile" ]]; then
    return
  fi

  log "Configuring gemmini-rocc-tests build directory"
  (
    cd "${GEMMINI_TESTS}"
    ./build.sh bareMetalC
  )
}

build_tiling_tests() {
  local shape=$1
  local resume_test_index=$2
  local resume_i=$3
  local resume_j=$4
  local resume_k=$5

  parse_shape "${shape}"

  local dim_defs="-DMAT_DIM_I=${MAT_I} -DMAT_DIM_J=${MAT_J} -DMAT_DIM_K=${MAT_K}"
  local build_dir="${GEMMINI_TESTS}/build/bareMetalC"
  local idx target start_i start_j start_k start_defs

  if [[ "${RUN_MODE}" == "fixed" ]]; then
    local generic_target="fixed_tiling_matmul_test-linux"
    local fixed_i fixed_j fixed_k gemmini_config fixed_defs

    log "Building fixed tiling matmul tests for ${shape}"
    require_linux_compiler
    ensure_build_configured
    mkdir -p "${build_dir}"

    for idx in "${!BUILD_TARGETS[@]}"; do
      target="${BUILD_TARGETS[$idx]}"
      read -r fixed_i fixed_j fixed_k <<< "$(fixed_tile_for_test_index "${shape}" "${idx}")"
      gemmini_config=$(fixed_gemmini_configuration_for_test_index "${idx}")
      fixed_defs="-DGEMMINI_CONFIGURATION=${gemmini_config} -DFIXED_TILE_I=${fixed_i} -DFIXED_TILE_J=${fixed_j} -DFIXED_TILE_K=${fixed_k}"

      log "  ${target}: config ${gemmini_config}, tile ${fixed_i},${fixed_j},${fixed_k}"
      rm -f "${build_dir}/${generic_target}" "${build_dir}/${target}"
      (
        cd "${build_dir}"
        make -j"$(nproc)" \
          -f "${GEMMINI_TESTS}/bareMetalC/Makefile" \
          abs_top_srcdir="${GEMMINI_TESTS}" \
          src_dir="${GEMMINI_TESTS}/bareMetalC" \
          PREFIX=examples-bareMetalC \
          XLEN=64 \
          EXTRA_CFLAGS="${dim_defs} ${fixed_defs}" \
          "${generic_target}"
        cp -f "${generic_target}" "${target}"
      )
    done
    return
  fi

  if is_llama_run_mode; then
    local generic_target="llama_shape_test-linux"
    local packed a_packed b_packed c_packed d_packed count gemmini_config
    local fixed_i fixed_j fixed_k multi use_hugepage hugepage_log2
    local matmul_mode vm_page_bytes llama_defs

    log "Building llama-shape tests for ${shape}"
    require_linux_compiler
    ensure_build_configured
    mkdir -p "${build_dir}"

    for idx in "${!BUILD_TARGETS[@]}"; do
      target="${BUILD_TARGETS[$idx]}"
      packed="${LLAMA_TEST_PAGE_PACKED[$idx]}"
      a_packed="${LLAMA_TEST_A_PACKED[$idx]}"
      b_packed="${LLAMA_TEST_B_PACKED[$idx]}"
      c_packed="${LLAMA_TEST_C_PACKED[$idx]}"
      d_packed="${LLAMA_TEST_D_PACKED[$idx]}"
      count="${LLAMA_TEST_GEMMINI_COUNT[$idx]}"
      multi="${LLAMA_TEST_MULTI[$idx]}"
      use_hugepage="${LLAMA_TEST_USE_HUGEPAGE[$idx]}"
      hugepage_log2="${LLAMA_TEST_HUGEPAGE_LOG2[$idx]}"
      if [[ "${RUN_MODE}" == "llama_shape_single32" ]]; then
        gemmini_config="${LLAMA_SINGLE32_GEMMINI_CONFIGURATION}"
      else
        gemmini_config=$(gemmini_configuration_for_count "${count}")
      fi
      if [[ "${multi}" == "1" ]]; then
        matmul_mode=multi
      else
        matmul_mode=single
      fi
      if [[ "${use_hugepage}" == "1" ]]; then
        vm_page_bytes=$((1 << hugepage_log2))
      else
        vm_page_bytes=4096
      fi
      read -r fixed_i fixed_j fixed_k <<< "$(llama_tile_for_gemmini_count "${count}")"
      llama_defs="-DGEMMINI_CONFIGURATION=${gemmini_config} -DMULTI=${multi} -DUSE_HUGEPAGE=${use_hugepage} -DHUGEPAGE_LOG2=${hugepage_log2} -DGEMMINI_PAGE_PACKED_MATMUL=${packed} -DGEMMINI_PAGE_PACKED_A=${a_packed} -DGEMMINI_PAGE_PACKED_B=${b_packed} -DGEMMINI_PAGE_PACKED_C=${c_packed} -DGEMMINI_PAGE_PACKED_D=${d_packed} -DFIXED_TILE_I=${fixed_i} -DFIXED_TILE_J=${fixed_j} -DFIXED_TILE_K=${fixed_k} -DCHECK=${LLAMA_CHECK}"

      log "  ${target}: matmul_mode=${matmul_mode}, vm_page=${vm_page_bytes} (hugepage=${use_hugepage}), page_packed=${packed}, A/B/C/D=${a_packed}/${b_packed}/${c_packed}/${d_packed}, gemmini_count=${count}, config ${gemmini_config}, tile ${fixed_i},${fixed_j},${fixed_k}, check=${LLAMA_CHECK}"
      rm -f "${build_dir}/${generic_target}" "${build_dir}/${target}"
      (
        cd "${build_dir}"
        make -j"$(nproc)" \
          -f "${GEMMINI_TESTS}/bareMetalC/Makefile" \
          abs_top_srcdir="${GEMMINI_TESTS}" \
          src_dir="${GEMMINI_TESTS}/bareMetalC" \
          PREFIX=examples-bareMetalC \
          XLEN=64 \
          EXTRA_CFLAGS="${dim_defs} ${llama_defs}" \
          "${generic_target}"
        cp -f "${generic_target}" "${target}"
      )
    done
    return
  fi

  log "Building tiling swap tests for ${shape}; resume test index ${resume_test_index} at ${resume_i},${resume_j},${resume_k}"
  require_linux_compiler
  ensure_build_configured
  mkdir -p "${build_dir}"

  for idx in "${!BUILD_TARGETS[@]}"; do
    target="${BUILD_TARGETS[$idx]}"
    start_i=1
    start_j=1
    start_k=1
    if (( idx == resume_test_index )); then
      start_i=${resume_i}
      start_j=${resume_j}
      start_k=${resume_k}
    fi

    start_defs="-DSTART_TILE_I=${start_i} -DSTART_TILE_J=${start_j} -DSTART_TILE_K=${start_k}"
    rm -f "${build_dir}/${target}"
    (
      cd "${build_dir}"
      make -j"$(nproc)" \
        -f "${GEMMINI_TESTS}/bareMetalC/Makefile" \
        abs_top_srcdir="${GEMMINI_TESTS}" \
        src_dir="${GEMMINI_TESTS}/bareMetalC" \
        PREFIX=examples-bareMetalC \
        XLEN=64 \
        EXTRA_CFLAGS="${dim_defs} ${start_defs}" \
        "${target}"
    )
  done
}

build_br_base_image() {
  local build_dir="${GEMMINI_TESTS}/build/bareMetalC"
  local generic_llama="${build_dir}/llama_shape_test-linux"
  local label
  local mode
  local count
  local target

  if [[ -f "${generic_llama}" ]]; then
    target="${build_dir}/llama_shape_test_2m_a0b0c0_1gem-linux"
    if [[ ! -f "${target}" ]]; then
      cp -f "${generic_llama}" "${target}"
    fi
    for label in row packed; do
      for count in 1 2 3 4; do
        target="${build_dir}/llama_shape_test_${label}_${count}gem-linux"
        if [[ ! -f "${target}" ]]; then
          cp -f "${generic_llama}" "${target}"
        fi
      done
    done
    for mode in 000 001 010 011 100 101 110 111; do
      label="a${mode:0:1}b${mode:1:1}c${mode:2:1}"
      for count in 1 2 3 4; do
        target="${build_dir}/llama_shape_test_${label}_${count}gem-linux"
        if [[ ! -f "${target}" ]]; then
          cp -f "${generic_llama}" "${target}"
        fi
      done
    done
  fi

  log "Building br-base FireMarshal image"
  (
    cd "${FIREMARSHAL_DIR}"
    if [[ "${RUN_INIT_SUBMODULES}" == "1" && "${init_submodules_done}" == "0" ]]; then
      ./init-submodules.sh
    fi
    ./marshal -v build br-base.json
  )
  init_submodules_done=1

  log "Copying br-base artifacts into gemmini-uniform workload"
  for artifact in br-base-bin br-base-bin-dwarf br-base.img; do
    cp -v "${BR_BASE_IMAGE_DIR}/${artifact}" "${WORKLOAD_DIR}/"
  done
}

wait_for_remote_screen() {
  local deadline=$((SECONDS + BOOT_TIMEOUT_SECONDS))
  local count
  log "Waiting for remote screen session ${SCREEN_NAME}"

  while true; do
    count=$(remote_screen_count)
    if [[ "${count}" == "1" ]]; then
      return
    fi
    if [[ "${count}" != "0" ]]; then
      printf 'Found %s remote screen sessions named "%s"; clean up stale sessions first\n' \
        "${count}" "${SCREEN_NAME}" >&2
      return 1
    fi
    if (( SECONDS >= deadline )); then
      printf 'Timed out waiting for screen session "%s"\n' "${SCREEN_NAME}" >&2
      return 1
    fi
    sleep 5
  done
}

remote_screen_count() {
  ssh_cmd "screen -ls | grep -c '[.]${SCREEN_NAME}[[:space:]]' || true"
}

wait_for_remote_screen_gone() {
  local deadline=$((SECONDS + REMOTE_SCREEN_EXIT_TIMEOUT_SECONDS))
  local count

  while true; do
    count=$(remote_screen_count)
    if [[ "${count}" == "0" ]]; then
      return
    fi
    if (( SECONDS >= deadline )); then
      printf 'Timed out waiting for remote screen session "%s" to exit\n' \
        "${SCREEN_NAME}" >&2
      return 1
    fi
    sleep 2
  done
}

ensure_no_remote_screen_before_start() {
  local count
  count=$(remote_screen_count)
  if [[ "${count}" == "0" ]]; then
    return
  fi

  if [[ "${count}" != "1" ]]; then
    printf 'Found %s remote screen sessions named "%s"; clean up stale sessions first\n' \
      "${count}" "${SCREEN_NAME}" >&2
    return 1
  fi

  if [[ "${KILL_STALE_REMOTE_SCREEN}" == "1" ]]; then
    log "Found stale remote screen session ${SCREEN_NAME}; killing it before starting a new attempt"
    kill_remote_screen
    wait_for_remote_screen_gone
    return
  fi

  cat >&2 <<EOF
Remote screen session "${SCREEN_NAME}" already exists before starting a new runworkload.
This usually means a previous automation run exited while the simulator was still alive.
Kill the stale screen manually, or rerun with KILL_STALE_REMOTE_SCREEN=1 if it is safe to stop it.
EOF
  return 1
}

remote_uart_contains() {
  local pattern=$1
  local uart
  uart=$(remote_uart_path)
  ssh_cmd "test -f $(quote "${uart}") && grep -aqF -- $(quote "${pattern}") $(quote "${uart}")"
}

remote_uart_mtime() {
  local uart
  uart=$(remote_uart_path)
  ssh_cmd "test -f $(quote "${uart}") && stat -c %Y $(quote "${uart}") || echo 0"
}

remote_uart_size() {
  local uart
  uart=$(remote_uart_path)
  ssh_cmd "test -f $(quote "${uart}") && stat -c %s $(quote "${uart}") || echo 0"
}

remote_uart_contains_after_offset() {
  local pattern=$1
  local offset=$2
  local uart
  uart=$(remote_uart_path)
  ssh_cmd "test -f $(quote "${uart}") && size=\$(stat -c %s $(quote "${uart}")) && if [ \"\${size}\" -lt $(quote "${offset}") ]; then start=1; else start=$((offset + 1)); fi && tail -c +\${start} $(quote "${uart}") | grep -aqF -- $(quote "${pattern}")"
}

wait_for_remote_uart_pattern() {
  local pattern=$1
  local description=$2
  local offset=${3:-0}
  local deadline=$((SECONDS + BOOT_TIMEOUT_SECONDS))
  log "Waiting for ${description} in remote UART log"

  until remote_uart_contains_after_offset "${pattern}" "${offset}"; do
    if (( SECONDS >= deadline )); then
      printf 'Timed out waiting for %s in %s\n' "${description}" "$(remote_uart_path)" >&2
      return 1
    fi
    sleep 10
  done
}

screen_stuff_line() {
  local line=$1
  local payload
  payload=$(quote "${line}"$'\r')
  ssh_cmd "screen -S $(quote "${SCREEN_NAME}") -X stuff ${payload}"
}

kill_remote_screen() {
  log "Killing remote screen session ${SCREEN_NAME}"
  ssh_cmd "screen -S $(quote "${SCREEN_NAME}") -X quit || true"
  wait_for_remote_screen_gone || true
}

monitor_guest_test() {
  local test_name=$1
  local end_marker=$2
  local last_mtime
  local mtime
  local last_update
  local status

  last_mtime=$(remote_uart_mtime)
  last_update=${SECONDS}
  log "Monitoring ${test_name}; stall timeout ${STALL_TIMEOUT_SECONDS}s"

  while true; do
    status=$(remote_end_status "${end_marker}")
    if [[ -n "${status}" ]]; then
      return 0
    fi

    if [[ -n "${runworkload_pid}" ]] && ! kill -0 "${runworkload_pid}" 2>/dev/null; then
      log "firesim runworkload process exited before ${test_name} end marker was observed"
      return 11
    fi

    mtime=$(remote_uart_mtime)
    if [[ "${mtime}" != "${last_mtime}" ]]; then
      last_mtime=${mtime}
      last_update=${SECONDS}
    fi

    if (( SECONDS - last_update >= STALL_TIMEOUT_SECONDS )); then
      log "Detected stall in ${test_name}: no UART update for ${STALL_TIMEOUT_SECONDS}s"
      return 10
    fi

    sleep "${MONITOR_POLL_SECONDS}"
  done
}

fetch_remote_uart() {
  local dest=$1
  local uart
  uart=$(remote_uart_path)
  ssh_cmd "test -f $(quote "${uart}") && cat $(quote "${uart}") || true" > "${dest}"
}

uart_file_end_status() {
  local uart_file=$1
  local end_marker=$2

  if [[ ! -f "${uart_file}" ]]; then
    return
  fi

  tr -d '\000' < "${uart_file}" | awk -v marker="${end_marker}" '
    index($0, marker) {
      if (match($0, /status=[0-9]+/)) {
        s = substr($0, RSTART + 7, RLENGTH - 7)
      } else {
        s = "malformed"
      }
    }
    END {
      if (s != "") {
        print s
      }
    }
  '
}

last_completed_tile_after_marker() {
  local start_marker=$1
  local tmp
  tmp=$(mktemp)
  fetch_remote_uart "${tmp}"

  tr -d '\000' < "${tmp}" | awk -v marker="${start_marker}" '
    index($0, marker) { seen = 1; next }
    seen {
      line = $0
      sub(/\r$/, "", line)
      if (match(line, /^tile_I: [0-9]+, tile_J: [0-9]+, tile_K: [0-9]+, .*Average cycle: [0-9]+/)) {
        text = substr(line, RSTART, RLENGTH)
        gsub(/[^0-9]+/, " ", text)
        sub(/^ /, "", text)
        sub(/ $/, "", text)
        split(text, a, " ")
        i = a[1]
        j = a[2]
        k = a[3]
      }
    }
    END {
      if (i != "") {
        print i, j, k
      }
    }
  '

  rm -f "${tmp}"
}

remote_end_status() {
  local end_marker=$1
  local tmp
  local status
  tmp=$(mktemp)
  fetch_remote_uart "${tmp}"

  status=$(uart_file_end_status "${tmp}" "${end_marker}")

  rm -f "${tmp}"
  printf '%s\n' "${status}"
}

result_end_status_from_run_log() {
  local run_log=$1
  local end_marker=$2
  local result_dir
  local uart

  result_dir=$(result_dir_from_run_log "${run_log}")
  if [[ -z "${result_dir}" ]]; then
    return
  fi

  uart="${result_dir}/gemmini-uniform0/uartlog"
  uart_file_end_status "${uart}" "${end_marker}"
}

next_tile_after() {
  local shape=$1
  local tile_i=$2
  local tile_j=$3
  local tile_k=$4
  local dim max_i max_j max_k

  parse_shape "${shape}"
  dim=$(gemmini_dim)
  if [[ -z "${dim}" || ! "${dim}" =~ ^[0-9]+$ ]]; then
    printf 'Could not read DIM from %s\n' "${GEMMINI_PARAMS}" >&2
    return 2
  fi

  max_i=$(((MAT_I + dim - 1) / dim))
  max_j=$(((MAT_J + dim - 1) / dim))
  max_k=$(((MAT_K + dim - 1) / dim))

  if (( tile_k < max_k )); then
    printf '%d %d %d\n' "${tile_i}" "${tile_j}" "$((tile_k + 1))"
  elif (( tile_j < max_j )); then
    printf '%d %d %d\n' "${tile_i}" "$((tile_j + 1))" 1
  elif (( tile_i < max_i )); then
    printf '%d %d %d\n' "$((tile_i + 1))" 1 1
  else
    return 1
  fi
}

llama_required_hugepages_for_shape() {
  local shape=$1
  local hugepage_log2=$2
  local page_bytes
  local a_bytes
  local b_bytes
  local c_bytes
  local off_b
  local off_c
  local mapping_bytes

  parse_shape "${shape}"
  page_bytes=$((1 << hugepage_log2))

  # llama_shape_test uses int8 A/B and int32 C, with each DMA buffer starting
  # at a separate hugepage boundary. D is absent because NO_BIAS defaults true.
  a_bytes=$((MAT_I * MAT_K))
  b_bytes=$((MAT_K * MAT_J))
  c_bytes=$((MAT_I * MAT_J * 4))
  off_b=$((((a_bytes + page_bytes - 1) / page_bytes) * page_bytes))
  off_c=$(((((off_b + b_bytes + page_bytes - 1) / page_bytes) * page_bytes)))
  mapping_bytes=$(((((off_c + c_bytes + page_bytes - 1) / page_bytes) * page_bytes)))

  printf '%d\n' "$((mapping_bytes / page_bytes))"
}

wait_for_runworkload() {
  if [[ -z "${runworkload_pid}" ]]; then
    return
  fi

  if [[ "${RUNWORKLOAD_TIMEOUT_SECONDS}" == "0" ]]; then
    wait "${runworkload_pid}"
    runworkload_pid=""
    return
  fi

  local deadline=$((SECONDS + RUNWORKLOAD_TIMEOUT_SECONDS))
  while kill -0 "${runworkload_pid}" 2>/dev/null; do
    if (( SECONDS >= deadline )); then
      printf 'Timed out waiting for firesim runworkload after %s seconds\n' \
        "${RUNWORKLOAD_TIMEOUT_SECONDS}" >&2
      return 1
    fi
    sleep 30
  done

  wait "${runworkload_pid}"
  runworkload_pid=""
}

latest_result_dir_since() {
  local marker=$1
  find "${RESULTS_DIR}" -mindepth 1 -maxdepth 1 -type d \
    -name '*-gemmini-uniform' -newer "${marker}" | sort | tail -1
}

result_dir_from_run_log() {
  local run_log=$1
  awk '
    /This workload'\''s output is located in:/ {
      getline
      gsub(/\r/, "")
      print
      exit
    }
  ' "${run_log}"
}

write_llama_shape_summary_csv() {
  local shape=$1
  local attempt=$2
  local outcome=$3
  local dest=$4
  local uart="${dest}/uartlog"
  local csv="${dest}/llama_shape_summary.csv"

  if [[ ! -f "${uart}" ]]; then
    return
  fi

  {
    printf '%s\n' "${LLAMA_SUMMARY_HEADER}"
    tr -d '\000' < "${uart}" | awk \
      -v fallback_shape="${shape}" \
      -v fallback_attempt="${attempt}" \
      -v outcome="${outcome}" '
      function reset() {
        test_name = ""
        current_shape = fallback_shape
        current_attempt = fallback_attempt
        page_packed = ""
        a_packed = ""
        b_packed = ""
        c_packed = ""
        d_packed = ""
        gemmini_count = ""
        gemmini_configuration = ""
        mat_i = ""
        mat_j = ""
        mat_k = ""
        tile_i = ""
        tile_j = ""
        tile_k = ""
        weight_cache_prepare = ""
        activation_quantization = ""
        gemmini_job_setup = ""
        gemmini_matmul = ""
        output_dequantization = ""
        total = ""
        matmul_mode = ""
        use_hugepage = ""
        vm_page_bytes = ""
        hugepages_requested = ""
        hugepages_reserved = ""
        hugepage_reservation_status = ""
        rdma_tlb_wait_cycles_sum = ""
        rdma_tl_wait_cycles_sum = ""
        rdma_bytes_rec_sum = ""
        rdma_total_latency_sum = ""
        wdma_tlb_wait_cycles_sum = ""
        wdma_tl_wait_cycles_sum = ""
        wdma_bytes_sent_sum = ""
        wdma_total_latency_sum = ""
        dma_tlb_total_req_sum = ""
        dma_tlb_hit_req_sum = ""
        dma_tlb_miss_req_sum = ""
        dma_tlb_miss_cycle_sum = ""
        rdma_active_cycle_sum = ""
        wdma_active_cycle_sum = ""
        load_dma_wait_cycle_sum = ""
        store_dma_wait_cycle_sum = ""
        load_active_cycle_sum = ""
      }

      function csv_field(value) {
        gsub(/"/, "\"\"", value)
        return "\"" value "\""
      }

      function add_counter(current, value) {
        return (current == "" ? 0 : current) + value
      }

      function infer_test_metadata() {
        if (test_name ~ /_a[01]b[01]c[01]_/) {
          layout = test_name
          sub(/^.*_a/, "", layout)
          sub(/_[0-9]+gem$/, "", layout)
          a_packed = substr(layout, 1, 1)
          b_packed = substr(layout, 3, 1)
          c_packed = substr(layout, 5, 1)
          d_packed = 0
          page_packed = (a_packed == 1 || b_packed == 1 || c_packed == 1) ? 1 : 0
        } else if (test_name ~ /_packed_/) {
          page_packed = 1
          a_packed = 1
          b_packed = 1
          c_packed = 1
          d_packed = 1
        } else if (test_name ~ /_row_/) {
          page_packed = 0
          a_packed = 0
          b_packed = 0
          c_packed = 0
          d_packed = 0
        }

        gemmini_count = test_name
        sub(/^.*_/, "", gemmini_count)
        sub(/gem$/, "", gemmini_count)
        if (gemmini_count !~ /^[0-9]+$/) {
          gemmini_count = ""
        }
      }

      function emit() {
        if (test_name == "") {
          return
        }

        if (dma_tlb_total_req_sum != "" && dma_tlb_hit_req_sum != "") {
          dma_tlb_miss_req_sum = dma_tlb_total_req_sum - dma_tlb_hit_req_sum
          if (dma_tlb_miss_req_sum < 0) {
            dma_tlb_miss_req_sum = 0
          }
        }

        print current_shape "," current_attempt "," outcome "," \
              csv_field(test_name) "," page_packed "," \
              a_packed "," b_packed "," c_packed "," d_packed "," \
              gemmini_count "," \
              gemmini_configuration "," mat_i "," mat_j "," mat_k "," \
              tile_i "," tile_j "," tile_k "," \
              weight_cache_prepare "," activation_quantization "," \
              gemmini_job_setup "," gemmini_matmul "," \
              output_dequantization "," total "," \
              matmul_mode "," use_hugepage "," vm_page_bytes "," \
              hugepages_requested "," hugepages_reserved "," \
              hugepage_reservation_status "," \
              rdma_tlb_wait_cycles_sum "," rdma_tl_wait_cycles_sum "," \
              rdma_bytes_rec_sum "," rdma_total_latency_sum "," \
              wdma_tlb_wait_cycles_sum "," wdma_tl_wait_cycles_sum "," \
              wdma_bytes_sent_sum "," wdma_total_latency_sum "," \
              dma_tlb_total_req_sum "," dma_tlb_hit_req_sum "," \
              dma_tlb_miss_req_sum "," dma_tlb_miss_cycle_sum "," \
              rdma_active_cycle_sum "," wdma_active_cycle_sum "," \
              load_dma_wait_cycle_sum "," store_dma_wait_cycle_sum "," \
              load_active_cycle_sum
      }

      BEGIN {
        reset()
      }

      {
        line = $0
        gsub(/\r/, "", line)
        gsub(/\033\[[0-9;?]*[[:alpha:]]/, "", line)

        if (index(line, "=== START ") > 0 && index(line, " attempt=") > 0) {
          reset()
          marker = line
          sub(/^.*=== START /, "", marker)
          sub(/ ===.*$/, "", marker)
          split(marker, parts, " ")
          test_name = parts[1]
          current_shape = parts[2]
          current_attempt = parts[3]
          sub(/^attempt=/, "", current_attempt)
          infer_test_metadata()
          next
        }

        if (test_name == "") {
          next
        }

        if (index(line, "MATMUL_MODE: ") > 0) {
          matmul_mode = line
          sub(/^.*MATMUL_MODE: /, "", matmul_mode)
          sub(/[[:space:]].*$/, "", matmul_mode)
          next
        }

        if (index(line, "USE_HUGEPAGE: ") > 0) {
          use_hugepage = line
          sub(/^.*USE_HUGEPAGE: /, "", use_hugepage)
          sub(/[^0-9].*$/, "", use_hugepage)
          next
        }

        if (index(line, "VM_PAGE_BYTES: ") > 0) {
          vm_page_bytes = line
          sub(/^.*VM_PAGE_BYTES: /, "", vm_page_bytes)
          sub(/[^0-9].*$/, "", vm_page_bytes)
          next
        }

        if (index(line, "HUGEPAGE-RESERVATION,") > 0) {
          hugepages_requested = line
          sub(/^.*requested=/, "", hugepages_requested)
          sub(/,.*/, "", hugepages_requested)
          hugepages_reserved = line
          sub(/^.*actual=/, "", hugepages_reserved)
          sub(/,.*/, "", hugepages_reserved)
          hugepage_reservation_status = line
          sub(/^.*status=/, "", hugepage_reservation_status)
          sub(/[^0-9].*$/, "", hugepage_reservation_status)
          next
        }

        if (index(line, "GEMMINI_PAGE_PACKED_MATMUL: ") > 0) {
          page_packed = line
          sub(/^.*GEMMINI_PAGE_PACKED_MATMUL: /, "", page_packed)
          sub(/[^0-9].*$/, "", page_packed)
          next
        }

        if (index(line, "GEMMINI_PAGE_PACKED_A: ") > 0) {
          a_packed = line
          sub(/^.*GEMMINI_PAGE_PACKED_A: /, "", a_packed)
          sub(/[^0-9].*$/, "", a_packed)
          next
        }

        if (index(line, "GEMMINI_PAGE_PACKED_B: ") > 0) {
          b_packed = line
          sub(/^.*GEMMINI_PAGE_PACKED_B: /, "", b_packed)
          sub(/[^0-9].*$/, "", b_packed)
          next
        }

        if (index(line, "GEMMINI_PAGE_PACKED_C: ") > 0) {
          c_packed = line
          sub(/^.*GEMMINI_PAGE_PACKED_C: /, "", c_packed)
          sub(/[^0-9].*$/, "", c_packed)
          next
        }

        if (index(line, "GEMMINI_PAGE_PACKED_D: ") > 0) {
          d_packed = line
          sub(/^.*GEMMINI_PAGE_PACKED_D: /, "", d_packed)
          sub(/[^0-9].*$/, "", d_packed)
          next
        }

        if (index(line, "gemmini_configuration: ") > 0) {
          gemmini_configuration = line
          sub(/^.*gemmini_configuration: /, "", gemmini_configuration)
          sub(/[[:space:]].*$/, "", gemmini_configuration)
          next
        }

        if (index(line, "MAT_DIM_I: ") > 0) {
          mat_i = line
          sub(/^.*MAT_DIM_I: /, "", mat_i)
          sub(/[^0-9].*$/, "", mat_i)
          next
        }

        if (index(line, "MAT_DIM_J: ") > 0) {
          mat_j = line
          sub(/^.*MAT_DIM_J: /, "", mat_j)
          sub(/[^0-9].*$/, "", mat_j)
          next
        }

        if (index(line, "MAT_DIM_K: ") > 0) {
          mat_k = line
          sub(/^.*MAT_DIM_K: /, "", mat_k)
          sub(/[^0-9].*$/, "", mat_k)
          next
        }

        if (index(line, "Fixed tile_I: ") > 0) {
          tiles = line
          gsub(/[^0-9]+/, " ", tiles)
          sub(/^ /, "", tiles)
          split(tiles, tile_parts, " ")
          tile_i = tile_parts[1]
          tile_j = tile_parts[2]
          tile_k = tile_parts[3]
          next
        }

        if (index(line, "GEMMINI-COUNTER,") > 0 &&
            index(line, ",name=") > 0 && index(line, ",value=") > 0) {
          counter_name = line
          sub(/^.*name=/, "", counter_name)
          sub(/,value=.*/, "", counter_name)
          counter_value = line
          sub(/^.*value=/, "", counter_value)
          sub(/[^0-9].*$/, "", counter_value)

          if (counter_name == "RDMA_TLB_WAIT_CYCLES") {
            rdma_tlb_wait_cycles_sum = add_counter(rdma_tlb_wait_cycles_sum, counter_value)
          } else if (counter_name == "RDMA_TL_WAIT_CYCLES") {
            rdma_tl_wait_cycles_sum = add_counter(rdma_tl_wait_cycles_sum, counter_value)
          } else if (counter_name == "RDMA_BYTES_REC") {
            rdma_bytes_rec_sum = add_counter(rdma_bytes_rec_sum, counter_value)
          } else if (counter_name == "RDMA_TOTAL_LATENCY") {
            rdma_total_latency_sum = add_counter(rdma_total_latency_sum, counter_value)
          } else if (counter_name == "WDMA_TLB_WAIT_CYCLES") {
            wdma_tlb_wait_cycles_sum = add_counter(wdma_tlb_wait_cycles_sum, counter_value)
          } else if (counter_name == "WDMA_TL_WAIT_CYCLES") {
            wdma_tl_wait_cycles_sum = add_counter(wdma_tl_wait_cycles_sum, counter_value)
          } else if (counter_name == "WDMA_BYTES_SENT") {
            wdma_bytes_sent_sum = add_counter(wdma_bytes_sent_sum, counter_value)
          } else if (counter_name == "WDMA_TOTAL_LATENCY") {
            wdma_total_latency_sum = add_counter(wdma_total_latency_sum, counter_value)
          } else if (counter_name == "DMA_TLB_TOTAL_REQ") {
            dma_tlb_total_req_sum = add_counter(dma_tlb_total_req_sum, counter_value)
          } else if (counter_name == "DMA_TLB_HIT_REQ") {
            dma_tlb_hit_req_sum = add_counter(dma_tlb_hit_req_sum, counter_value)
          } else if (counter_name == "DMA_TLB_MISS_CYCLE") {
            dma_tlb_miss_cycle_sum = add_counter(dma_tlb_miss_cycle_sum, counter_value)
          } else if (counter_name == "RDMA_ACTIVE_CYCLE") {
            rdma_active_cycle_sum = add_counter(rdma_active_cycle_sum, counter_value)
          } else if (counter_name == "WDMA_ACTIVE_CYCLE") {
            wdma_active_cycle_sum = add_counter(wdma_active_cycle_sum, counter_value)
          } else if (counter_name == "LOAD_DMA_WAIT_CYCLE") {
            load_dma_wait_cycle_sum = add_counter(load_dma_wait_cycle_sum, counter_value)
          } else if (counter_name == "STORE_DMA_WAIT_CYCLE") {
            store_dma_wait_cycle_sum = add_counter(store_dma_wait_cycle_sum, counter_value)
          } else if (counter_name == "LOAD_ACTIVE_CYCLE") {
            load_active_cycle_sum = add_counter(load_active_cycle_sum, counter_value)
          }
          next
        }

        if (index(line, "LLAMA-FLOW-CYCLES,stage=") > 0) {
          stage = line
          sub(/^.*stage=/, "", stage)
          sub(/,cycles=.*/, "", stage)
          cycles = line
          sub(/^.*cycles=/, "", cycles)
          sub(/[^0-9].*$/, "", cycles)

          if (stage == "weight_cache_prepare") {
            weight_cache_prepare = cycles
          } else if (stage == "activation_quantization") {
            activation_quantization = cycles
          } else if (stage == "gemmini_job_setup") {
            gemmini_job_setup = cycles
          } else if (stage == "gemmini_matmul") {
            gemmini_matmul = cycles
          } else if (stage == "output_dequantization") {
            output_dequantization = cycles
          } else if (stage == "total") {
            total = cycles
          }
          next
        }

        if (index(line, "=== END ") > 0 && index(line, test_name) > 0) {
          emit()
          reset()
          next
        }
      }

      END {
        emit()
      }
    '
  } > "${csv}"

  log "Wrote llama shape summary CSV to ${csv}"
}

refresh_llama_shape_summary_csv() {
  local csv="${RESULT_COPY_DIR}/llama_shape_summary.csv"
  local summary

  mkdir -p "${RESULT_COPY_DIR}"
  printf '%s\n' "${LLAMA_SUMMARY_HEADER}" > "${csv}"

  while IFS= read -r summary; do
    tail -n +2 "${summary}" >> "${csv}"
  done < <(find "${RESULT_COPY_DIR}" -mindepth 3 -maxdepth 3 -type f -name llama_shape_summary.csv | sort)

  log "Updated aggregate llama shape summary CSV at ${csv}"
}

archive_result() {
  local shape=$1
  local marker=$2
  local run_log=$3
  local attempt=$4
  local outcome=$5

  local result_dir
  result_dir=$(result_dir_from_run_log "${run_log}")
  if [[ -z "${result_dir}" || ! -d "${result_dir}" ]]; then
    result_dir=$(latest_result_dir_since "${marker}")
  fi
  if [[ -z "${result_dir}" ]]; then
    printf 'Could not find new gemmini-uniform result directory for %s attempt %s\n' \
      "${shape}" "${attempt}" >&2
    return 1
  fi

  local dest="${RESULT_COPY_DIR}/${shape}/attempt-${attempt}-${outcome}"
  mkdir -p "${dest}"
  cp -a "${run_log}" "${dest}/firesim-runworkload.log"

  if [[ -d "${result_dir}/gemmini-uniform0" ]]; then
    cp -a "${result_dir}/gemmini-uniform0/." "${dest}/"
  fi
  if [[ ! -f "${dest}/uartlog" ]]; then
    fetch_remote_uart "${dest}/uartlog" || true
  fi

  cat > "${dest}/metadata.txt" <<EOF
shape=${shape}
attempt=${attempt}
outcome=${outcome}
run_mode=${RUN_MODE}
firesim_result_dir=${result_dir}
archived_at=$(date --iso-8601=seconds)
EOF

  log "Archived ${shape} attempt ${attempt} (${outcome}) result to ${dest}"

  if is_llama_run_mode; then
    write_llama_shape_summary_csv "${shape}" "${attempt}" "${outcome}" "${dest}"
    refresh_llama_shape_summary_csv
  fi
}

run_firesim_shape_attempt() {
  local shape=$1
  local start_test_index=$2
  local resume_i=$3
  local resume_j=$4
  local resume_k=$5
  local attempt=$6

  local marker
  local local_run_dir
  local run_log
  local current_test_index
  local test_name
  local start_marker
  local end_marker
  local monitor_rc
  local status
  local wait_status
  local last_tile
  local next_tile
  local uart_search_offset
  local use_hugepage
  local required_hugepages

  marker=$(mktemp "${DEPLOY_DIR}/.tiling-swap-marker.XXXXXX")
  local_run_dir="${RESULT_COPY_DIR}/${shape}/attempt-${attempt}-live"
  run_log="${local_run_dir}/firesim-runworkload.live.log"
  mkdir -p "${local_run_dir}"

  ensure_no_remote_screen_before_start

  log "Running firesim infrasetup for ${shape} attempt ${attempt}"
  (
    cd "${DEPLOY_DIR}"
    ./firesim infrasetup
  )

  ssh_cmd "rm -f $(quote "$(remote_uart_path)") && test ! -e $(quote "$(remote_uart_path)")"
  uart_search_offset=$(remote_uart_size)

  log "Starting firesim runworkload for ${shape} attempt ${attempt}"
  (
    cd "${DEPLOY_DIR}"
    ./firesim runworkload
  ) > "${run_log}" 2>&1 &
  runworkload_pid=$!

  wait_for_remote_screen
  wait_for_remote_uart_pattern "login:" "guest login prompt" "${uart_search_offset}"
  screen_stuff_line "root"
  sleep 5
  screen_stuff_line "stty -echo"
  sleep 1
  screen_stuff_line "echo \"=== TILING_SWAP_AUTOMATION SHAPE ${shape} ATTEMPT ${attempt} START ===\""

  current_test_index=${start_test_index}
  while (( current_test_index < ${#GUEST_TESTS[@]} )); do
    test_name=${GUEST_TESTS[$current_test_index]}
    start_marker="=== START ${test_name} ${shape} attempt=${attempt} ==="
    end_marker="=== END ${test_name} ${shape} attempt=${attempt} status="

    log "Running ${test_name} for ${shape} attempt ${attempt}"
    screen_stuff_line "echo \"${start_marker}\""
    if [[ "${RUN_MODE}" == "llama_shape_single32" ]]; then
      use_hugepage="${LLAMA_TEST_USE_HUGEPAGE[$current_test_index]}"
      if [[ "${use_hugepage}" == "1" ]]; then
        required_hugepages=$(llama_required_hugepages_for_shape \
          "${shape}" "${LLAMA_TEST_HUGEPAGE_LOG2[$current_test_index]}")
        log "Reserving ${required_hugepages} 2 MiB HugeTLB pages for ${test_name}"
        screen_stuff_line "if echo ${required_hugepages} > /proc/sys/vm/nr_hugepages 2>/dev/null && grep -qx \"${required_hugepages}\" /proc/sys/vm/nr_hugepages; then echo \"HUGEPAGE-RESERVATION,requested=${required_hugepages},actual=${required_hugepages},status=0\"; if /usr/bin/${test_name}; then echo \"${end_marker}0 ===\"; else echo \"${end_marker}1 ===\"; fi; else printf \"HUGEPAGE-RESERVATION,requested=${required_hugepages},actual=\"; tr -d '\\n' < /proc/sys/vm/nr_hugepages 2>/dev/null || printf 0; echo \",status=7\"; echo \"${end_marker}7 ===\"; fi"
      else
        screen_stuff_line "echo 0 > /proc/sys/vm/nr_hugepages 2>/dev/null || true; echo \"HUGEPAGE-RESERVATION,requested=0,actual=0,status=0\"; if /usr/bin/${test_name}; then echo \"${end_marker}0 ===\"; else echo \"${end_marker}1 ===\"; fi"
      fi
    else
      screen_stuff_line "/usr/bin/${test_name}"
      screen_stuff_line "echo \"${end_marker}\$? ===\""
    fi

    monitor_rc=0
    monitor_guest_test "${test_name}" "${end_marker}" || monitor_rc=$?
    if (( monitor_rc == 0 )); then
      status=$(remote_end_status "${end_marker}")
      if [[ "${status}" != "0" ]]; then
        log "${test_name} exited with status ${status:-unknown}"
        screen_stuff_line "sync"
        screen_stuff_line "poweroff -f"
        wait_status=0
        wait_for_runworkload || wait_status=$?
        archive_result "${shape}" "${marker}" "${run_log}" "${attempt}" "failed"
        rm -f "${marker}"
        if [[ "${status}" =~ ^[0-9]+$ && "${status}" != "0" ]]; then
          return "${status}"
        fi
        return 1
      fi

      log "Completed ${test_name} for ${shape}"
      current_test_index=$((current_test_index + 1))
      resume_i=1
      resume_j=1
      resume_k=1

      if is_llama_run_mode; then
        screen_stuff_line "echo \"=== TILING_SWAP_AUTOMATION SHAPE ${shape} ATTEMPT ${attempt} END ===\""
        screen_stuff_line "sync"
        screen_stuff_line "poweroff -f"

        wait_status=0
        wait_for_runworkload || wait_status=$?
        archive_result "${shape}" "${marker}" "${run_log}" "${attempt}" "completed"
        rm -f "${marker}"

        NEXT_TEST_INDEX=${current_test_index}
        NEXT_START_I=1
        NEXT_START_J=1
        NEXT_START_K=1
        return "${wait_status}"
      fi

      continue
    fi

    if (( monitor_rc != 10 )); then
      if (( monitor_rc == 11 )); then
        wait_status=0
        wait_for_runworkload || wait_status=$?
        if (( wait_status != 0 )); then
          log "firesim runworkload exited with status ${wait_status}"
        fi

        status=$(remote_end_status "${end_marker}")
        if [[ -z "${status}" ]]; then
          status=$(result_end_status_from_run_log "${run_log}" "${end_marker}")
        fi

        if [[ "${status}" == "0" ]]; then
          log "Completed ${test_name} for ${shape}; observed end marker after runworkload exit"
          current_test_index=$((current_test_index + 1))
          archive_result "${shape}" "${marker}" "${run_log}" "${attempt}" "completed"
          rm -f "${marker}"

          NEXT_TEST_INDEX=${current_test_index}
          NEXT_START_I=1
          NEXT_START_J=1
          NEXT_START_K=1
          return 0
        fi

        if [[ -n "${status}" ]]; then
          log "${test_name} exited with status ${status} after runworkload exit"
          archive_result "${shape}" "${marker}" "${run_log}" "${attempt}" "failed"
          rm -f "${marker}"
          return "${status}"
        fi

        NEXT_TEST_INDEX=${current_test_index}
        NEXT_START_I=${resume_i}
        NEXT_START_J=${resume_j}
        NEXT_START_K=${resume_k}
        kill_remote_screen
        archive_result "${shape}" "${marker}" "${run_log}" "${attempt}" "runworkload-exited"
        rm -f "${marker}"
        return 10
      fi

      kill_remote_screen
      wait_for_runworkload || true
      archive_result "${shape}" "${marker}" "${run_log}" "${attempt}" "monitor-error"
      rm -f "${marker}"
      return "${monitor_rc}"
    fi

    if [[ "${RUN_MODE}" == "fixed" ]]; then
      NEXT_TEST_INDEX=${current_test_index}
      read -r NEXT_START_I NEXT_START_J NEXT_START_K <<< "$(fixed_tile_for_test_index "${shape}" "${current_test_index}")"
      log "Will retry fixed tile ${NEXT_START_I},${NEXT_START_J},${NEXT_START_K} for ${test_name}"
    elif [[ "${RUN_MODE}" == "sweep" ]]; then
      last_tile=$(last_completed_tile_after_marker "${start_marker}" || true)
      if [[ -n "${last_tile}" ]]; then
        read -r resume_i resume_j resume_k <<< "${last_tile}"
        if next_tile=$(next_tile_after "${shape}" "${resume_i}" "${resume_j}" "${resume_k}"); then
          read -r NEXT_START_I NEXT_START_J NEXT_START_K <<< "${next_tile}"
          NEXT_TEST_INDEX=${current_test_index}
          log "Will resume ${test_name} after completed tile ${resume_i},${resume_j},${resume_k}; next ${NEXT_START_I},${NEXT_START_J},${NEXT_START_K}"
        else
          NEXT_TEST_INDEX=$((current_test_index + 1))
          NEXT_START_I=1
          NEXT_START_J=1
          NEXT_START_K=1
          log "Last completed tile was final for ${test_name}; continuing with next test"
        fi
      else
        NEXT_TEST_INDEX=${current_test_index}
        NEXT_START_I=${resume_i}
        NEXT_START_J=${resume_j}
        NEXT_START_K=${resume_k}
        log "No completed tile found for ${test_name}; retrying from ${NEXT_START_I},${NEXT_START_J},${NEXT_START_K}"
      fi
    else
      NEXT_TEST_INDEX=${current_test_index}
      NEXT_START_I=1
      NEXT_START_J=1
      NEXT_START_K=1
      log "Will retry ${test_name} from the beginning"
    fi

    kill_remote_screen
    wait_status=0
    wait_for_runworkload || wait_status=$?
    if (( wait_status != 0 )); then
      log "firesim runworkload exited with status ${wait_status} after screen kill"
    fi
    archive_result "${shape}" "${marker}" "${run_log}" "${attempt}" "stalled"
    rm -f "${marker}"
    return 10
  done

  screen_stuff_line "echo \"=== TILING_SWAP_AUTOMATION SHAPE ${shape} ATTEMPT ${attempt} END ===\""
  screen_stuff_line "sync"
  screen_stuff_line "poweroff -f"

  wait_status=0
  wait_for_runworkload || wait_status=$?
  archive_result "${shape}" "${marker}" "${run_log}" "${attempt}" "completed"
  rm -f "${marker}"

  NEXT_TEST_INDEX=${current_test_index}
  NEXT_START_I=1
  NEXT_START_J=1
  NEXT_START_K=1
  return "${wait_status}"
}

run_shape_with_resume() {
  local shape=$1
  local current_test_index=0
  local start_i=1
  local start_j=1
  local start_k=1
  local attempt=1
  local run_rc

  if is_llama_run_mode; then
    log "=== Building llama-shape binaries and rootfs for ${shape} ==="
    build_tiling_tests "${shape}" 0 1 1 1
    build_br_base_image
  fi

  while (( current_test_index < ${#GUEST_TESTS[@]} )); do
    if [[ "${RUN_MODE}" == "fixed" ]]; then
      read -r start_i start_j start_k <<< "$(fixed_tile_for_test_index "${shape}" "${current_test_index}")"
    fi
    log "=== Starting shape ${shape} attempt ${attempt}; test index ${current_test_index}, start ${start_i},${start_j},${start_k} ==="

    if ! is_llama_run_mode; then
      build_tiling_tests "${shape}" "${current_test_index}" "${start_i}" "${start_j}" "${start_k}"
      build_br_base_image
    fi

    run_rc=0
    run_firesim_shape_attempt "${shape}" "${current_test_index}" "${start_i}" "${start_j}" "${start_k}" "${attempt}" || run_rc=$?
    if (( run_rc == 0 )); then
      current_test_index=${NEXT_TEST_INDEX}
      start_i=${NEXT_START_I}
      start_j=${NEXT_START_J}
      start_k=${NEXT_START_K}
      attempt=$((attempt + 1))
      continue
    fi

    if (( run_rc == 10 )); then
      current_test_index=${NEXT_TEST_INDEX}
      start_i=${NEXT_START_I}
      start_j=${NEXT_START_J}
      start_k=${NEXT_START_K}
      attempt=$((attempt + 1))
      continue
    fi

    return "${run_rc}"
  done

  log "=== Finished shape ${shape} ==="
}

main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
  fi

  configure_run_mode

  local shapes=("$@")
  if [[ ${#shapes[@]} -eq 0 ]]; then
    if [[ "${RUN_MODE}" == "llama_shape" ]]; then
      shapes=("${LLAMA_DEFAULT_SHAPES[@]}")
    elif [[ "${RUN_MODE}" == "llama_shape_single32" ]]; then
      shapes=("${LLAMA_SINGLE32_DEFAULT_SHAPES[@]}")
    else
      shapes=("${DEFAULT_SHAPES[@]}")
    fi
  fi

  for shape in "${shapes[@]}"; do
    parse_shape "${shape}"
  done

  mkdir -p "${RESULT_COPY_DIR}"

  for shape in "${shapes[@]}"; do
    run_shape_with_resume "${shape}"
  done

  log "All requested shapes completed"
}

main "$@"
