import pytest

from dbt.tests.adapter.catalog import files
from dbt.artifacts.schemas.catalog import CatalogArtifact
from dbt.tests.adapter.catalog.relation_types import CatalogRelationTypes


class TestCatalogRelationTypes(CatalogRelationTypes):
    @pytest.fixture(scope="class", autouse=True)
    def models(self):
        yield {
            "my_table.sql": files.MY_TABLE,
            "my_view.sql": files.MY_VIEW,
        }

    @pytest.mark.parametrize(
        "node_name,relation_type",
        [
            ("seed.test.my_seed", "table"),
            ("model.test.my_table", "table"),
            ("model.test.my_view", "view"),
        ],
    )
    def test_relation_types_populate_correctly(
        self, docs: CatalogArtifact, node_name: str, relation_type: str
    ):
        super().test_relation_types_populate_correctly(docs, node_name, relation_type)
