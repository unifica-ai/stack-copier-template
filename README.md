# Stack Copier Template

## Create

```
copier copy --answers-file=.copier-answers-stack.yml  gh:unifica-ai/stack-copier-template /path/to/project
```

## Update

```
copier copy --answers-file=.copier-answers-stack.yml update .
```


## Manual touch up:

Add to `smtpreal` in `common.yaml`:

```
- ./config/user-patches.sh:/tmp/docker-mailserver/user-patches.sh:ro
```
