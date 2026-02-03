k8s_yaml('./k8s/postgres.yaml')

k8s_resource(
    'postgres',
    port_forwards=5432,
)

k8s_resource(
    'pgadmin',
    port_forwards='5050:80',
    links=['http://localhost:5050'],
)

local_resource(
    'init_db',
    'PGPASSWORD=password psql -h localhost -p 5432 -U user -d postgres -f ./fhir/ddl/fhir_database.sql',
    trigger_mode=TRIGGER_MODE_MANUAL,
    resource_deps=['postgres'],
    allow_parallel=False,
)

local_resource(
    'seed_db',
    'python main.py',
    trigger_mode=TRIGGER_MODE_MANUAL,
    resource_deps=['init_db'],
)

local_resource(
    'apply_task_model',
    'PGPASSWORD=password psql -h localhost -p 5432 -U user -d postgres -f ./DataModeling/task_model.sql',
    trigger_mode=TRIGGER_MODE_MANUAL,
    deps=['DataModeling/task_model.sql'],
    resource_deps=['postgres'],
)
