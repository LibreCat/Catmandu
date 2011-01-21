# In your conf/db.yml write something like:
---
db:
  class: Catmandu::Store::Merge
  args:
    patha: data/aleph.db
    pathb: data/fedora.db
