const chai = require('chai');
const chaiHttp = require('chai-http');
const app = require('../app');
const expect = chai.expect;

chai.use(chaiHttp);

describe('API Endpoints', () => {
  it('should return 200 on health check', (done) => {
    chai.request(app)
      .get('/health') // Adjust endpoint if different
      .end((err, res) => {
        expect(res).to.have.status(200);
        done();
      });
  });
});