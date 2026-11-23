package GitPulseUI {
    private import ScalarValues::*;

    part def MainWindow {
        part headerBar : PathSelectorPanel[1];
        part statusSummary : ScanStatusPanel[1];
        part repositoryTable : RepositoryDataGrid[1];
        part actionPanel : CleanupActionPanel[1];
    }

    part def PathSelectorPanel {
        attribute pathInput : String;
        part browseButton;
        part scanButton;
    }

    part def ScanStatusPanel {
        attribute statusMessage : String;
        attribute isThresholdWarning : Boolean;
    }

    part def RepositoryDataGrid {
        part selectAllCheckbox;
        part rows : RepositoryRow[*];
    }

    part def RepositoryRow {
        attribute isSelected : Boolean;
        attribute repoName : String;
        attribute relativePath : String;
        attribute activeBranch : String;
        attribute gitStatus : String;
        attribute artifactSize : String;
        attribute lastCommit : String;
    }

    part def CleanupActionPanel {
        part cleanButton;
        attribute selectedSizeText : String;
    }
}