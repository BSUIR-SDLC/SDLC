// @diagram ibd "Логическая модель данных RuleHook"
package Data {
  part user : User {
    attribute id : uuid; attribute login : text; attribute password_hash : text;
    attribute role : ADMIN|OPERATOR|VIEWER; attribute failed_attempts : int; attribute locked_until : timestamptz;
  }
  part source : Source {
    @Primary;
    attribute id : uuid; attribute name : text; attribute secret_ref : text; attribute prev_secret_ref : text;
    attribute allowed_types : text[]; attribute rate_limit_rps : int; attribute enabled : bool;
  }
  part target : Target {
    @Primary;
    attribute id : uuid; attribute name : text; attribute kind : EMULATOR|NOTIFIER; attribute base_url : text;
    attribute auth_ref : text; attribute timeout_ms : int; attribute enabled : bool;
  }
  part rule : Rule {
    @Primary;
    attribute id : uuid; attribute source_id : →Source; attribute event_type : text; attribute priority : int;
    attribute enabled : bool; attribute version : int; attribute definition : jsonb; attribute cooldown_s : int;
    attribute disabled_reason : text?;
  }
  part ruleVersion : RuleVersion {
    attribute rule_id : →Rule; attribute version : int; attribute definition : jsonb; attribute author_id : →User; attribute ts : timestamptz;
  }
  part event : Event {
    @Core;
    attribute id : bigserial; attribute source_id : →Source; attribute external_id : text; attribute type : text;
    attribute payload : jsonb; attribute hop : int; attribute received_at : timestamptz;
  }
  part ruleMatch : RuleMatch {
    @Core;
    attribute id : bigserial; attribute event_id : →Event; attribute rule_id : →Rule; attribute rule_version : int; attribute explain : jsonb;
  }
  part delivery : Delivery {
    @Core;
    attribute id : uuid; attribute match_id : →RuleMatch; attribute target_id : →Target; attribute status : text;
    attribute attempts : int; attribute next_attempt_at : timestamptz; attribute response_code : int?; attribute request_body : jsonb;
  }
  part deadLetter : DeadLetter {
    attribute delivery_id : →Delivery; attribute reason : text; attribute failed_at : timestamptz; attribute replay_id : →Replay?;
  }
  part loopTrip : LoopTrip {
    attribute id : bigserial; attribute rule_id : →Rule; attribute kind : HOP|COOLDOWN|BREAKER; attribute ts : timestamptz;
  }
  part replay : Replay {
    attribute id : uuid; attribute author_id : →User; attribute filter : jsonb; attribute count : int; attribute ts : timestamptz;
  }
  part setting : SystemSetting {
    attribute key : text; attribute value : jsonb; attribute updated_at : timestamptz;
  }
  connect source to rule { doc /* 1 — 0..* */ }
  connect rule to ruleVersion { doc /* 1 — 1..* */ }
  connect source to event { doc /* 1 — 0..* */ }
  connect event to ruleMatch { doc /* 1 — 0..* */ }
  connect rule to ruleMatch { doc /* 1 — 0..* */ }
  connect ruleMatch to delivery { doc /* 1 — 1..* */ }
  connect target to delivery { doc /* 1 — 0..* */ }
  connect delivery to deadLetter { doc /* 1 — 0..1 */ }
  connect rule to loopTrip { doc /* 1 — 0..* */ }
  connect user to ruleVersion { doc /* 1 — 0..* */ }
  connect replay to deadLetter { doc /* 1 — 0..* */ }
  connect user to replay { doc /* 1 — 0..* */ }
}
