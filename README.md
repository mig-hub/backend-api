REST API
--------

Use Rack::MethodOverride if you don't have access to HTTP methods like PUT or DELETE

ORM
---

Adapter is loaded automatically if known and required before Backend

How to plug an ORM to ::Rack::Backend ?
---------------------------------------

Model::backend_single( id ) Should return a single database entry with the id provided