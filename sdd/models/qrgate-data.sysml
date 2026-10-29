package QRGate_Data {
    doc /* Логическая модель данных QRGate (SDD, представление 004). Типы атрибутов соответствуют PostgreSQL. */

    part def User {
        attribute id : uuid;
        attribute login : text;
        attribute password_hash : text;
        attribute role : CONTROLLER_or_ADMIN;
        attribute failed_attempts : int;
        attribute locked_until : timestamptz;
    }
    part def Site {
        attribute id : uuid;
        attribute name : text;
        attribute capacity : int;
        attribute warn_threshold_pct : int;
        attribute antipassback_strict : bool;
        attribute capacity_lock : bool;
        attribute timezone : text;
    }
    part def Zone {
        attribute id : uuid;
        attribute site_id : FK_Site;
        attribute name : text;
    }
    part def Checkpoint {
        attribute id : uuid;
        attribute zone_id : FK_Zone;
        attribute name : text;
    }
    part def ControllerCheckpoint {
        attribute user_id : FK_User;
        attribute checkpoint_id : FK_Checkpoint;
    }
    part def Holder {
        attribute id : uuid;
        attribute full_name : text;
        attribute email : text;
        attribute photo_id : uuid_null;
        attribute photo_consent_at : timestamptz;
    }
    part def Pass {
        attribute id : uuid;
        attribute code : P_or_G_NNNNNN;
        attribute holder_id : FK_Holder;
        attribute type : EMPLOYEE_or_GUEST;
        attribute valid_from : timestamptz;
        attribute valid_to : timestamptz;
        attribute status : ACTIVE_or_REVOKED;
        attribute version : int;
        attribute legal_basis : text;
    }
    part def PassZone {
        attribute pass_id : FK_Pass;
        attribute zone_id : FK_Zone;
    }
    part def Presence {
        attribute pass_id : FK_Pass;
        attribute site_id : FK_Site;
        attribute inside : bool;
        attribute changed_at : timestamptz;
    }
    part def SiteCounter {
        attribute site_id : FK_Site;
        attribute inside : int;
        attribute updated_at : timestamptz;
    }
    part def AccessEvent {
        attribute id : bigserial;
        attribute ts : timestamptz;
        attribute checkpoint_id : FK_Checkpoint;
        attribute pass_id : FK_Pass_null;
        attribute controller_id : FK_User;
        attribute direction : IN_or_OUT;
        attribute decision : ALLOW_or_DENY;
        attribute reason : text;
        attribute manual : bool;
        attribute latency_ms : int;
    }
    part def CounterReset {
        attribute id : uuid;
        attribute site_id : FK_Site;
        attribute author_id : FK_User_null;
        attribute reason : text;
        attribute ts : timestamptz;
    }

    part qrgateData {
        attribute w = 1900; attribute h = 1100;
        attribute title = "Логическая модель данных QRGate";

        part user : User { attribute x = 40; attribute y = 90; attribute w = 380; attribute list = 1; }
        part controllerCheckpoint : ControllerCheckpoint { attribute x = 40; attribute y = 470; attribute w = 380; attribute list = 1; }
        part counterReset : CounterReset { attribute x = 1000; attribute y = 258; attribute w = 380; attribute list = 1; }
        part site : Site { attribute x = 520; attribute y = 90; attribute w = 380; attribute list = 1; attribute color = "system"; }
        part zone : Zone { attribute x = 520; attribute y = 470; attribute w = 380; attribute list = 1; }
        part checkpoint : Checkpoint { attribute x = 520; attribute y = 720; attribute w = 380; attribute list = 1; }
        part siteCounter : SiteCounter { attribute x = 1000; attribute y = 70; attribute w = 380; attribute list = 1; attribute color = "core"; }
        part passZone : PassZone { attribute x = 1000; attribute y = 470; attribute w = 380; attribute list = 1; }
        part accessEvent : AccessEvent { attribute x = 1000; attribute y = 720; attribute w = 380; attribute list = 1; attribute color = "core"; }
        part holder : Holder { attribute x = 1480; attribute y = 90; attribute w = 380; attribute list = 1; }
        part pass : Pass { attribute x = 1480; attribute y = 410; attribute w = 380; attribute list = 1; attribute color = "system"; }
        part presence : Presence { attribute x = 1480; attribute y = 880; attribute w = 380; attribute list = 1; }

        connection r1 connect user to controllerCheckpoint { doc /* 1 — 0..* */ }
        connection r2 connect site to zone { doc /* 1 — 1..* */ }
        connection r3 connect zone to checkpoint { doc /* 1 — 1..* */ }
        connection r4 connect checkpoint to controllerCheckpoint { doc /* 1 — 0..* */ }
        connection r5 connect site to siteCounter { doc /* 1 — 1 */ }
        connection r6 connect holder to pass { doc /* 1 — 0..* */ }
        connection r7 connect pass to passZone { doc /* 1 — 1..* */ }
        connection r8 connect zone to passZone { doc /* 1 — 0..* */ }
        connection r9 connect pass to presence { doc /* 1 — 0..1 на объект */ }
        connection r10 connect checkpoint to accessEvent { doc /* 1 — 0..* */ }
        connection r11 connect pass to accessEvent { doc /* 0..1 — 0..* */ }
        connection r12 connect site to counterReset { doc /* 1 — 0..* */ }
    }
}
