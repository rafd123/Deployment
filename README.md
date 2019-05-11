## Bootstrap

Base:
```
irm https://raw.githubusercontent.com/rafd123/Deployment/master/bootstrap.ps1 | iex
```

Dev:
```
& { $DeployType = 'dev'; irm https://raw.githubusercontent.com/rafd123/Deployment/master/bootstrap.ps1 | iex }
```
