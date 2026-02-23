import { getPermalink, getBlogPermalink } from '~/utils/permalinks';

export const headerData = {
  links: [
    {
      text: 'Blog',
      href: getBlogPermalink(),
    },
    {
      text: 'Railroad',
      href: getPermalink('railroad', 'tag'),
    },
    {
      text: 'Docs',
      href: getPermalink('doc', 'tag'),
    },
    {
      text: 'About',
      href: getPermalink('/about'),
    },
  ],
  actions: [],
};

export const footerData = {
  links: [],
  secondaryLinks: [],
  socialLinks: [],
  footNote: `
    Boser-Guyon Web · All rights reserved.
  `,
};
