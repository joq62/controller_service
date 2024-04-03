-define(CatalogEbin,"catalog/catalog/ebin").
-define(SpecsEbin,"specs/specs/ebin").

-define(ReconciliationInterval,60*1000).

%%---------- Log
-define(MainLogDir,"logs").
-define(LocalLogDir,"log.logs").
-define(LogFile,"test_logfile").
-define(MaxNumFiles,10).
-define(MaxNumBytes,100000).

-define(InfraApplicationFileNames,
	["catalog.application",
	 "controller.application",
	 "deployment.application",
	 "log.application",
	 "resource_discovery.application"]).
