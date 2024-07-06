import unittest
from multiprocessing import get_context
from unittest import mock
import dbt.flags as flags
from dbt.adapters.iris import IRISAdapter

from .utils import config_from_parts_or_dicts, mock_connection


class TestIRISAdapter(unittest.TestCase):
    def setUp(self):
        pass
        flags.STRICT_MODE = True

        profile_cfg = {
            "outputs": {
                "test": {
                    "type": "iris",
                    "hostname": "thishostshouldnotexist",
                    "port": 1972,
                    "namespace": "USER",
                    "schema": "dbt",
                    "username": "dbt",
                    "password": "dbt",
                }
            },
            "target": "test",
        }

        project_cfg = {
            "name": "X",
            "version": "0.1",
            "profile": "test",
            "project-root": "/tmp/dbt/does-not-exist",
            "quoting": {
                "identifier": False,
                "schema": True,
            },
            "config-version": 2,
        }

        self.config = config_from_parts_or_dicts(project_cfg, profile_cfg)
        self.mp_context = get_context("spawn")
        self._adapter = None

    @property
    def adapter(self):
        if self._adapter is None:
            self._adapter = IRISAdapter(self.config, self.mp_context)
        return self._adapter

    @mock.patch("dbt.adapters.iris.connections.dbapi")
    def test_acquire_connection(self, connector):
        connection = self.adapter.acquire_connection("dummy")

        connector.connect.assert_not_called()
        connection.handle
        self.assertEqual(connection.state, "open")
        self.assertNotEqual(connection.handle, None)
        connector.connect.assert_called_once()

    def test_cancel_open_connections_empty(self):
        self.assertEqual(len(list(self.adapter.cancel_open_connections())), 0)

    def test_cancel_open_connections_main(self):
        key = self.adapter.connections.get_thread_identifier()
        self.adapter.connections.thread_connections[key] = mock_connection("main")
        self.assertEqual(len(list(self.adapter.cancel_open_connections())), 0)

    def test_placeholder(self):
        pass
