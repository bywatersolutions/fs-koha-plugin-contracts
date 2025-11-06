# Contracts plugin for Koha

This plugin adds the ability to manage contracts/copyright permissions
for biblios within Koha.

## Installation

Download from the release page

## Plugin Configuration

TBA

## Development

### Running Tests with KTD

This plugin uses Koha Testing Docker (KTD) for development and testing.

#### Prerequisites

- Docker and Docker Compose
- koha-testing-docker repository cloned locally

#### Setup and Test Execution

```bash
# 1. Set up KTD environment
export KTD_HOME=/path/to/koha-testing-docker
export PLUGINS_DIR=/path/to/koha-plugins  # Parent directory containing fscontracts
cd $KTD_HOME

# 2. Launch KTD instance with plugins support
ktd --proxy --name fscontracts --plugins up -d

# 3. Wait for KTD to be ready
ktd --name fscontracts --wait-ready 120

# 4. Install plugins in KTD
ktd --name fscontracts --shell --run "cd /kohadevbox/koha && perl misc/devel/install_plugins.pl"

# 5. Run plugin tests
ktd --name fscontracts --shell --run "
  cd /kohadevbox/plugins/fscontracts &&
  export PERL5LIB=\$PERL5LIB:Koha/Plugin/Com/ByWaterSolutions/Contracts/lib:. &&
  prove -v -r -s t/
"

# 6. Cleanup when done
ktd --name fscontracts down
```

#### Development Workflow

```bash
# Get into KTD shell for development
ktd --name fscontracts --shell

# Inside KTD:
cd /kohadevbox/plugins/fscontracts
export PERL5LIB=$PERL5LIB:Koha/Plugin/Com/ByWaterSolutions/Contracts/lib:.

# Run specific tests
prove -v t/specific_test.t

# Run all tests
prove -v -r -s t/
```

### CI/CD

The plugin uses GitHub Actions for continuous integration, testing against multiple Koha versions (main, stable, oldstable) using the same KTD setup.
