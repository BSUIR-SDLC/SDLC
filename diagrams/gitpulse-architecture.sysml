package GitPulseArchitecture {
    private import ScalarValues::*;

    part def GitPulseSystem {
        part ui : GitPulseUI;
        part core : GitPulseCore;
        part infrastructure : GitPulseInfrastructure;
        part storage : LocalStorage;
        part gitCli : GitCLI;

        connect ui.mainViewModel to core.diskScannerService;
        connect ui.mainViewModel to core.cleanupService;
        connect ui.mainViewModel to core.cacheThresholdService;

        connect core.diskScannerService to infrastructure.gitCliExecutor;
        connect core.diskScannerService to infrastructure.osFileSystemProvider;
        connect core.cleanupService to infrastructure.osFileSystemProvider;
        connect core.cleanupService to infrastructure.fileLogger;

        connect infrastructure.osFileSystemProvider to storage;
        connect infrastructure.gitCliExecutor to gitCli;
    }

    part def GitPulseUI {
        part mainWindow;
        part confirmDialog;
        part mainViewModel;

        connect mainWindow to mainViewModel;
        connect mainViewModel to confirmDialog;
    }

    part def GitPulseCore {
        part diskScannerService;
        part cleanupService;
        part cacheThresholdService;
    }

    part def GitPulseInfrastructure {
        part fileLogger;
        part osFileSystemProvider;
        part gitCliExecutor;
    }

    part def LocalStorage;

    part def GitCLI {
        attribute minVersion : String = ">= 2.40";
    }
}