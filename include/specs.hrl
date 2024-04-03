
-ifdef(PRODUCTION).
-define(ENVIRONMENT, production).
-else.
-define(ENVIRONMENT, test).
-endif.
