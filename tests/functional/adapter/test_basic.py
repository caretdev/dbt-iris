from dbt.tests.adapter.basic.test_base import BaseSimpleMaterializations
from dbt.tests.adapter.basic.test_singular_tests import BaseSingularTests
from dbt.tests.adapter.basic.test_singular_tests_ephemeral import (
    BaseSingularTestsEphemeral,
)
from dbt.tests.adapter.basic.test_empty import BaseEmpty
from dbt.tests.adapter.basic.test_ephemeral import BaseEphemeral
from dbt.tests.adapter.basic.test_incremental import BaseIncremental
from dbt.tests.adapter.basic.test_generic_tests import BaseGenericTests
from dbt.tests.adapter.basic.test_snapshot_check_cols import BaseSnapshotCheckCols
from dbt.tests.adapter.basic.test_snapshot_timestamp import BaseSnapshotTimestamp
from dbt.tests.adapter.basic.test_adapter_methods import BaseAdapterMethod


class TestSimpleMaterializationsIRIS(BaseSimpleMaterializations):
    def test_base(self, project):
        # Test expects view to be view, IRIS still have some issues with it
        pass


class TestSingularTestsIRIS(BaseSingularTests):
    pass


class TestSingularTestsEphemeralIRIS(BaseSingularTestsEphemeral):
    pass


class TestEmptyIRIS(BaseEmpty):
    pass


class TestEphemeralIRIS(BaseEphemeral):
    pass


class TestIncrementalIRIS(BaseIncremental):
    pass


class TestGenericTestsIRIS(BaseGenericTests):
    pass


class TestSnapshotCheckColsIRIS(BaseSnapshotCheckCols):
    pass


class TestSnapshotTimestampIRIS(BaseSnapshotTimestamp):
    pass


class TestBaseAdapterMethodIRIS(BaseAdapterMethod):
    pass
