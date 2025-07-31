This is a [GitHub Action](https://github.com/features/actions) that updates the contents of a post on [Ghost](https://ghost.org/) (blog) with the contents of a file in the caller's repository.

## Requirements
Here are the Linux packages required from the caller to use this GitHub Action.

* [`jq`](https://jqlang.org/)
* [`gawk`](https://man7.org/linux/man-pages/man1/gawk.1.html)
* [`curl`](https://curl.se/)
* [`bash`](https://en.wikipedia.org/wiki/Bash_(Unix_shell))

On Debian and Ubuntu systems, you most likely will only need to install `jq` and `gawk` separately in your caller repository's workflow like the below step.

```yaml
- name: Install dependencies for Ghost Post Update Action.
  run: sudo apt update && sudo apt install -y jq gawk
  shell: bash
```

## Inputs
Here are a list of inputs you will need to pass to the action from your repository (the caller). 

| Name | Default | Description |
| ---- | ------- | ----------- |
| `verbose` | `1` | What verbose output to print in the workflow (0 = None. 1 = Basic updates which includes post ID. 2 = everything from value 1, but with response output from the Ghost API via cURL. 3 = Escaped strings and more verbose cURL output) |
| `env_file` | `.gpua/.env` | The environmental file to load. Look at [Environment Configuration](#environment-configuration) for more details! |
| `file` | `README.md` | The local Markdown file whose contents will replace the Ghost post. |
| `ghost_api_url` | *N/A* | The Ghost API URL (e.g., `https://blog.moddingcommunity.com/ghost/api/admin`). |
| `ghost_admin_api_key` | *N/A* | The Ghost Admin API key retrieved from custom integration. |
| `ghost_post_id` | *N/A* | The Ghost post ID to update. |

**NOTE** - The **only optional** inputs are `verbose`, `env_file`, and `file`.

### Security Note
It is **strongly recommended** you use repository secrets to safely pass your Ghost's API information to the action.

To add secrets, go to your repository's **Settings** page -> **Security and variables** -> **Actions** -> **Repository secrets** -> **New repository secret**.

## Environment Configuration
The script that processes and updates the final Markdown contents before updating the Ghost post loads an environment file if the path to the value of `env_file` exists (default is `.gpua/.env`).

Here is the configuration for that file. The following general variables are available to set inside of the environmental file if specified through the `env_file` input setting.

| Name | Default | Description |
| ---- | ------- | ----------- |
| `LINES_SKIP` | *N/A* | A list of line numbers to skip in the final Markdown output to the Ghost post separated by commas (if multiple lines). |

### Header Links
This action supports mapping header link URLs if needed.

For example, say you have the following header links.

```markdown
* [Something 1](#something-1)
* [Something 2](#something-2)
```

However, on the Ghost post, the header link for *Something 1* is `#something-3`. You can use this feature to ensure the Ghost post contains this.

```markdown
* [Something 1](#something-3)
* [Something 2](#something-2)
```

The prefix for each link environmental variable is `LINK_`. When setting the environmental variable, you'll need to convert all letters to upper-case and replace `-` with `_`.

For example:

* `#something-1` => `LINK_SOMETHING_2`
* `#something--2` => `LINK_SOMETHING__3`

Here's an example of setting environmental variables that maps the two links above.

```
LINK_SOMETHING_1="something-2"
LINK_SOMETHING__2="something--3"
```

## Workflow Example
Here's a full workflow example on the caller's side.

```yaml
name: Update Ghost Post

on:
  push:
    branches: [ main ]

jobs:
  update-ghost-post:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout repository
      uses: actions/checkout@v4

    - name: Install dependencies for Ghost Post Update Action.
      run: sudo apt update && sudo apt install -y jq gawk
      shell: bash

    - uses: gamemann/ghost-post-update-action@v1.0.0
      with:
        file: CONTENTS.md
        ghost_api_url: ${{ secrets.GHOST_API_URL }}
        ghost_admin_api_key: ${{ secrets.GHOST_ADMIN_API_KEY }}
        ghost_post_id: ${{ secrets.GHOST_POST_ID }}
```

Then inside of the repository are repository secrets set using the steps mentioned earlier.

## My Motives & Examples
I create a lot of guides on my modding community [blog](#) with a GitHub repository in its [organization](https://github.com/modcommunity) since both GitHub and Ghost support the Markdown syntax.

This action allows me to update the guide through GitHub then the workflow automatically updates the contents of the post on the modding community blog.

Here are some guides from my modding community using this neat GitHub Action!

* [How To Set Up Steam Link On A Raspberry Pi](https://github.com/modcommunity/steam-link-with-raspberry-pi-setup)
* [How To Make A Left 4 Dead 2 Server With Mods](https://github.com/modcommunity/how-to-make-a-l4d2-server-with-mods)
* [How To Download & Run SteamCMD](https://github.com/modcommunity/how-to-download-and-run-steamcmd)
* [How To Set Up A Rust Game Server](https://github.com/modcommunity/how-to-set-up-a-rust-game-server)

## Credits
* [Christian Deacon](https://github.com/gamemann)
