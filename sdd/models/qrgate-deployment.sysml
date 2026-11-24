package QRGate_Deployment {
    doc /* Развёртывание QRGate релиза 1.0-2.0: один VPS с Docker Compose на объект заказчика
     * (SDD, представление 009, ADR-0007). */

    part def Smartphone { doc /* Android 10+ / Chrome 100+ или iOS 16+ / Safari 16+, камера с автофокусом. */ }
    part def Workstation { doc /* ПК администратора, экран от 1280×720, актуальный браузер. */ }
    part def Vps { doc /* VPS 2 vCPU, 4 ГБ RAM, 40 ГБ SSD, Ubuntu 24.04, Docker 24+. */ }
    part def Container { }
    part def Artifact { }
    part def Volume { }
    part def CiNode { doc /* GitHub Actions: lint, тесты, сборка образов; GitHub Container Registry. */ }

    part qrgateDeployment {
        attribute w = 1900; attribute h = 1080;
        attribute title = "Развёртывание QRGate";

        part phone : Smartphone {
            attribute x = 40; attribute y = 110; attribute w = 380; attribute h = 330; attribute stereo = "device";
            part scannerPwa : Artifact { attribute x = 30; attribute y = 170; attribute w = 320; attribute h = 120; attribute stereo = "artifact";
                doc /* Сканер PWA, статика в кэше service worker */ }
        }
        part pc : Workstation {
            attribute x = 40; attribute y = 640; attribute w = 380; attribute h = 310; attribute stereo = "device";
            part adminSpa : Artifact { attribute x = 30; attribute y = 160; attribute w = 320; attribute h = 110; attribute stereo = "artifact";
                doc /* Панель администратора SPA */ }
        }
        part vps : Vps {
            attribute x = 560; attribute y = 80; attribute w = 1010; attribute h = 950; attribute stereo = "node"; attribute color = "system";
            part nginx : Container { attribute x = 40; attribute y = 140; attribute w = 400; attribute h = 190; attribute stereo = "container";
                doc /* nginx:1.27 — порты 80/443, TLS Let's Encrypt (certbot), статика сканера и панели */ }
            part api : Container { attribute x = 560; attribute y = 140; attribute w = 410; attribute h = 190; attribute stereo = "container"; attribute color = "core";
                doc /* qrgate-api (node:20-alpine) — порт 3000 только во внутренней сети, переменные из .env */ }
            part db : Container { attribute x = 560; attribute y = 450; attribute w = 410; attribute h = 170; attribute stereo = "container"; attribute color = "store";
                doc /* postgres:16 — порт 5432 только во внутренней сети */ }
            part pgdata : Volume { attribute x = 560; attribute y = 730; attribute w = 410; attribute h = 160; attribute stereo = "volume";
                doc /* pgdata: данные PostgreSQL */ }
            part photos : Volume { attribute x = 40; attribute y = 450; attribute w = 400; attribute h = 170; attribute stereo = "volume";
                doc /* photos: фото владельцев (JPEG) */ }
            part backup : Container { attribute x = 40; attribute y = 730; attribute w = 400; attribute h = 170; attribute stereo = "cron";
                doc /* Ежедневный pg_dump в 03:00, хранение 14 копий вне VPS */ }

            connection nginxApi connect nginx to api { doc /* HTTP :3000, WS */ }
            connection apiDb connect api to db { doc /* TCP :5432 */ }
            connection dbVolume connect db to pgdata { doc /* mount */ }
            connection apiPhotos connect api to photos { doc /* mount */ }
            connection backupDb connect backup to db { doc /* pg_dump */ }
        }
        part ci : CiNode { attribute x = 1640; attribute y = 110; attribute w = 240; attribute h = 330; attribute stereo = "node"; }

        connection phoneLink connect phone to vps.nginx { doc /* HTTPS 443, 4G / Wi-Fi */ }
        connection pcLink connect pc to vps.nginx { doc /* HTTPS + WSS 443 */ }
        connection ciLink connect ci to vps.api { doc /* docker pull образов */ }
    }
}
