# Comments (Giscus)

This blog uses [Giscus](https://giscus.app/) for comments. Giscus uses GitHub Discussions as a backend.

## Setup

1.  **Create a Repository**: Create a public GitHub repository to hold your comments (e.g., `blog-comments`).
2.  **Enable Discussions**: Go to the repository settings and enable **Discussions**.
3.  **Install Giscus App**: Install the [giscus GitHub App](https://github.com/apps/giscus) and grant it access to the discussions repository.
4.  **Configure Giscus**: Visit [giscus.app](https://giscus.app/) and follow the instructions to generate your configuration.
5.  **Set Environment Variables**: Copy the following values from the giscus website into your `.env` file (or CI/CD environment variables):

    ```env
    PUBLIC_GISCUS_REPO="username/repo"
    PUBLIC_GISCUS_REPO_ID="R_..."
    PUBLIC_GISCUS_CATEGORY="Announcements"
    PUBLIC_GISCUS_CATEGORY_ID="DIC_..."
    ```

## Implementation Details

- The comments widget is rendered by `src/components/blog/Comments.astro`.
- It is only enabled if `PUBLIC_GISCUS_REPO` is set.
- It is integrated into the post detail layout at `src/pages/[access]/[...slug].astro`.
