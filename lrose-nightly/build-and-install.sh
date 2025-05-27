set -e

# Install into the shared drive
INSTALL_PREFIX=/share/lrose-nightly/
# Keep logs local to Job Pod so subsequent Jobs don't overwrite the logs
LOG_DIR=/lrose-nightly/build-logs

mkdir -p $LOG_DIR

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install --yes git python3

mkdir -p /root/git
cd /root/git
git clone https://github.com/NCAR/lrose-bootstrap
cd lrose-bootstrap

./scripts/run_install_linux_packages
python3 ./scripts/lrose_checkout_and_build_cmake.py \
  --prefix=$INSTALL_PREFIX \
  --logDir=$LOG_DIR

# Output version info
echo "LROSE-core version: $(TZ=US/Mountain date +%Y%m%d)" \
  | tee -a $LOG_DIR/git-checkout.log $INSTALL_PREFIX/LROSE_CORE_VERSION
