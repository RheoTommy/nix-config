# Removes the images that no build has used for three days, and the containers
# that interrupted builds left behind.

now=$(date +%s)

# Not younger ones: a build that is still running owns its container.
podman ps --all --external --format json |
  jq -r --argjson cutoff $((now - 24 * 3600)) \
    '.[] | select(.Status == "Storage" and .Created < $cutoff) | .Id' |
  xargs --no-run-if-empty podman rm

# Podman records when an image was created but not when a build last used it.
# A build that uses an image as cache creates a child of it, so an image counts
# as used while it has a recent descendant.
podman images --all --format json |
  jq -r --argjson cutoff $((now - 72 * 3600)) '
    unique_by(.Id)
    | (map({key: .Id, value: .ParentId}) | from_entries) as $parent
    | def keep($id):
        if $id == "" or $id == null or .[$id] then .
        else .[$id] = true | keep($parent[$id]) end;
      def depth($id):
        if $id == "" or $parent[$id] == null then 0
        else 1 + depth($parent[$id]) end;
    reduce (.[] | select(.Created >= $cutoff or .Containers > 0) | .Id) as $id
      ({}; keep($id)) as $kept
    | map(select($kept[.Id] | not) | .Id)
    # Children first, since Podman refuses to remove an image with children.
    | sort_by(-depth(.))
    | .[]' |
  xargs --no-run-if-empty podman rmi
