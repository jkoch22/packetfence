const { SCOPE_INSERT } = require('../config');

const url = '/configuration/domains';

module.exports = {
  id: 'domains',
  description: 'Domains',
  tests: [
    {
      description: 'Domains - Add New',
      scope: SCOPE_INSERT,
      fixture: 'collections/domain.json',
      url,
      interceptors: [
        {
          method: 'POST', url: '/api/**/config/domains', expectRequest: (req, fixture) => {
            Object.keys(fixture).forEach(key => {
              expect(req.body).to.have.property(key)
              expect(req.body[key]).to.deep.equal(fixture[key], key)
            })
          }
        }
      ]
    },
  ]
};