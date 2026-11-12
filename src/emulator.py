import argparse
import asyncio
import json
import logging
import random
import time
from typing import Any, Dict

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S"
)
logger = logging.getLogger("IoTDeviceEmulator")


class DeviceState:
    """Потокобезопасное хранилище состояния эмулятора (ADR-002)."""
    def __init__(self, device_id: str, interval_sec: int, token: str):
        self.lock = asyncio.Lock()
        self.device_id = device_id
        self.interval_sec = max(1, min(60, interval_sec))
        self.token = token
        self.base_temperature = 22.5
        self.temp_offset = 0.0
        self.mode = "NORMAL"
        self.is_running = True

    async def update(self, params: Dict[str, Any]) -> Dict[str, Any]:
        async with self.lock:
            if "interval_sec" in params:
                val = int(params["interval_sec"])
                if not (1 <= val <= 60):
                    raise ValueError("interval_sec must be between 1 and 60")
                self.interval_sec = val
            if "mode" in params:
                mode_val = str(params["mode"]).upper()
                if mode_val not in ("NORMAL", "ALERT"):
                    raise ValueError("mode must be NORMAL or ALERT")
                self.mode = mode_val
            if "target_temp_offset" in params:
                self.temp_offset = float(params["target_temp_offset"])
            return {
                "device_id": self.device_id,
                "interval_sec": self.interval_sec,
                "mode": self.mode,
                "temp_offset": self.temp_offset
            }

    async def snapshot(self) -> Dict[str, Any]:
        async with self.lock:
            is_alert = self.mode == "ALERT"
            jitter = random.uniform(-0.4, 0.4)
            alert_boost = 15.0 if is_alert and self.temp_offset == 0.0 else self.temp_offset
            temp = round(self.base_temperature + alert_boost + jitter, 2)
            motion = True if is_alert else random.choice([True, False, False])
            return {
                "device_id": self.device_id,
                "timestamp": int(time.time()),
                "temperature": temp,
                "motion": bool(motion),
                "status": self.mode
            }


async def telemetry_loop(state: DeviceState) -> None:
    """Фоновая корутина периодической генерации телеметрии (FR-1, FR-6)."""
    while state.is_running:
        payload = await state.snapshot()
        logger.info("TELEMETRY -> %s", json.dumps(payload, ensure_ascii=False))
        await asyncio.sleep(state.interval_sec)

mkdir -p src tests

cat << 'EOF' > src/emulator.py
import argparse
import asyncio
import json
import logging
import random
import time
from typing import Any, Dict

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S"
)
logger = logging.getLogger("IoTDeviceEmulator")


class DeviceState:
    """Потокобезопасное хранилище состояния эмулятора (ADR-002)."""
    def __init__(self, device_id: str, interval_sec: int, token: str):
        self.lock = asyncio.Lock()
        self.device_id = device_id
        self.interval_sec = max(1, min(60, interval_sec))
        self.token = token
        self.base_temperature = 22.5
        self.temp_offset = 0.0
        self.mode = "NORMAL"
        self.is_running = True

    async def update(self, params: Dict[str, Any]) -> Dict[str, Any]:
        async with self.lock:
            if "interval_sec" in params:
                val = int(params["interval_sec"])
                if not (1 <= val <= 60):
                    raise ValueError("interval_sec must be between 1 and 60")
                self.interval_sec = val
            if "mode" in params:
                mode_val = str(params["mode"]).upper()
                if mode_val not in ("NORMAL", "ALERT"):
                    raise ValueError("mode must be NORMAL or ALERT")
                self.mode = mode_val
            if "target_temp_offset" in params:
                self.temp_offset = float(params["target_temp_offset"])
            return {
                "device_id": self.device_id,
                "interval_sec": self.interval_sec,
                "mode": self.mode,
                "temp_offset": self.temp_offset
            }

    async def snapshot(self) -> Dict[str, Any]:
        async with self.lock:
            is_alert = self.mode == "ALERT"
            jitter = random.uniform(-0.4, 0.4)
            alert_boost = 15.0 if is_alert and self.temp_offset == 0.0 else self.temp_offset
            temp = round(self.base_temperature + alert_boost + jitter, 2)
            motion = True if is_alert else random.choice([True, False, False])
            return {
                "device_id": self.device_id,
                "timestamp": int(time.time()),
                "temperature": temp,
                "motion": bool(motion),
                "status": self.mode
            }


async def telemetry_loop(state: DeviceState) -> None:
    """Фоновая корутина периодической генерации телеметрии (FR-1, FR-6)."""
    while state.is_running:
        payload = await state.snapshot()
        logger.info("TELEMETRY -> %s", json.dumps(payload, ensure_ascii=False))
        await asyncio.sleep(state.interval_sec)


async def handle_client(reader: asyncio.StreamReader, writer: asyncio.StreamWriter, state: DeviceState) -> None:
    """Асинхронный HTTP-обработчик эндпоинта POST /command (FR-2, FR-3, FR-4, FR-7)."""
    try:
        raw_head = await reader.readuntil(b"\r\n\r\n")
        head_lines = raw_head.decode("utf-8", errors="replace").split("\r\n")
        request_line = head_lines[0].split()
        if len(request_line) < 2:
            return
        method, path = request_line[0], request_line[1]

        headers = {}
        for line in head_lines[1:]:
            if ":" in line:
                k, v = line.split(":", 1)
                headers[k.strip().lower()] = v.strip()

        content_length = int(headers.get("content-length", "0"))
        body_bytes = await reader.readexactly(content_length) if content_length > 0 else b""

        if method != "POST" or path != "/command":
            send_http(writer, 404, {"detail": "Not Found"})
            await writer.drain()
            return

        # Проверка авторизации Bearer Token (FR-7)
        auth_header = headers.get("authorization", "")
        if auth_header != f"Bearer {state.token}":
            logger.warning("UNAUTHORIZED /command attempt from peer")
            send_http(writer, 401, {"detail": "Invalid or missing Bearer token"})
            await writer.drain()
            return

        data = json.loads(body_bytes.decode("utf-8"))
        params = data.get("params", {})
        updated = await state.update(params)
        logger.info("COMMAND APPLIED -> %s", json.dumps(updated, ensure_ascii=False))
        send_http(writer, 200, {"status": "UPDATED", "state": updated})
        await writer.drain()

    except (ValueError, json.JSONDecodeError) as exc:
        send_http(writer, 422, {"detail": str(exc)})
        await writer.drain()
    except Exception:
        pass
    finally:
        writer.close()
        await writer.wait_closed()


def send_http(writer: asyncio.StreamWriter, status_code: int, body: Dict[str, Any]) -> None:
    reasons = {200: "OK", 401: "Unauthorized", 404: "Not Found", 422: "Unprocessable Entity"}
    payload = json.dumps(body, ensure_ascii=False).encode("utf-8")
    response = (
        f"HTTP/1.1 {status_code} {reasons.get(status_code, 'OK')}\r\n"
        f"Content-Type: application/json; charset=utf-8\r\n"
        f"Content-Length: {len(payload)}\r\n"
        f"Connection: close\r\n\r\n"
    ).encode("utf-8") + payload
    writer.write(response)


async def main() -> None:
    parser = argparse.ArgumentParser(description="IoT Device Emulator (Variant 8)")
    parser.add_argument("--host", default="127.0.0.1", help="Bind host")
    parser.add_argument("--port", type=int, default=8080, help="Bind port")
    parser.add_argument("--device-id", default="sensor-nord-08", help="Device identifier")
    parser.add_argument("--interval", type=int, default=5, help="Telemetry interval N (sec)")
    parser.add_argument("--token", default="secret-iot-token", help="Bearer auth token")
    args = parser.parse_args()

    state = DeviceState(device_id=args.device_id, interval_sec=args.interval, token=args.token)
    server = await asyncio.start_server(lambda r, w: handle_client(r, w, state), args.host, args.port)
    logger.info("Emulator started on http://%s:%d (device_id=%s, interval=%ds)",
                args.host, args.port, args.device_id, state.interval_sec)

    async with server:
        await asyncio.gather(server.serve_forever(), telemetry_loop(state))


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("Emulator stopped by user")
