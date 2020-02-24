const commonUtils = require('./common-utils');
const fs = require('fs');

const API_HOST = commonUtils.API_HOST;
const API_ROOT = commonUtils.API_ROOT;

const getInnerText = commonUtils.getInnerText;
const getInputValue = commonUtils.getInputValue;
const createResponseCallback = commonUtils.createResponseCallback;
const clearText = commonUtils.clearText;

describe('Share', () => {
  beforeAll(() => jest.setTimeout(60000));

  it('should generate a link', async done => {
    await page.goto(API_HOST);

    await page.click('#editor');
    await clearText(page.keyboard);
    await page.keyboard.type('asdf');

    const responseCallback = createResponseCallback(page, `${API_ROOT}/share`);
    await page.click('#share');
    await responseCallback;

    const actualShareLink = await page.evaluate(getInputValue, 'share-link');
    const expectedShareLink = `${API_HOST}/p/WxKPBq9-mkZ_kq4cMHXfCQ`;

    expect(actualShareLink).toEqual(expectedShareLink);
    done();
  });

  it('should work with v0 schema', async done => {
    const id = 'v0-schema';
    const expectedShareLink = `${API_HOST}/p/${id}`;
    const v0State = {
      language: 'cameligo',
      code: 'somecode',
      entrypoint: 'main',
      parameters: '1',
      storage: '2'
    };
    fs.writeFileSync(`/tmp/${id}.txt`, JSON.stringify(v0State));

    await page.goto(expectedShareLink);

    // Check share link is correct
    const actualShareLink = await page.evaluate(getInputValue, 'share-link');
    expect(actualShareLink).toEqual(expectedShareLink);

    // Check the code is correct. Note, because we are getting inner text we will get
    // a line number as well. Therefore the expected value has a '1' prefix
    const actualCode = await page.evaluate(getInnerText, 'editor');
    expect(actualCode).toContain(`1${v0State.code}`);

    // Check compile configuration
    await page.click('#command-select');
    await page.click('#compile');

    expect(await page.evaluate(getInputValue, 'entrypoint')).toEqual(
      v0State.entrypoint
    );

    // Check dry run configuration
    await page.click('#command-select');
    await page.click('#dry-run');

    expect(await page.evaluate(getInputValue, 'entrypoint')).toEqual(
      v0State.entrypoint
    );
    expect(await page.evaluate(getInputValue, 'parameters')).toEqual(
      v0State.parameters
    );
    expect(await page.evaluate(getInputValue, 'storage')).toEqual(
      v0State.storage
    );

    // Check deploy configuration
    await page.click('#command-select');
    await page.click('#deploy');

    expect(await page.evaluate(getInputValue, 'entrypoint')).toEqual(
      v0State.entrypoint
    );
    expect(await page.evaluate(getInputValue, 'storage')).toEqual(
      v0State.storage
    );

    // Check evaluate function configuration
    await page.click('#command-select');
    await page.click('#evaluate-function');

    expect(await page.evaluate(getInputValue, 'entrypoint')).toEqual(
      v0State.entrypoint
    );
    expect(await page.evaluate(getInputValue, 'parameters')).toEqual(
      v0State.parameters
    );

    // Check evaluate value configuration
    await page.click('#command-select');
    await page.click('#evaluate-value');

    expect(await page.evaluate(getInputValue, 'entrypoint')).toEqual(
      v0State.entrypoint
    );

    done();
  });

  it('should work with v1 schema', async done => {
    const id = 'v1-schema';
    const expectedShareLink = `${API_HOST}/p/${id}`;
    const v1State = {
      version: 'v1',
      state: {
        editor: {
          language: 'cameligo',
          code: 'somecode'
        },
        compile: {
          entrypoint: 'main'
        },
        dryRun: {
          entrypoint: 'main',
          parameters: '1',
          storage: '2'
        },
        deploy: {
          entrypoint: 'main',
          storage: '3',
          useTezBridge: false
        },
        evaluateFunction: {
          entrypoint: 'add',
          parameters: '(1, 2)'
        },
        evaluateValue: {
          entrypoint: 'a'
        }
      }
    };
    fs.writeFileSync(`/tmp/${id}.txt`, JSON.stringify(v1State));

    await page.goto(expectedShareLink);

    // Check share link is correct
    const actualShareLink = await page.evaluate(getInputValue, 'share-link');
    expect(actualShareLink).toEqual(expectedShareLink);

    // Check the code is correct. Note, because we are getting inner text we will get
    // a line number as well. Therefore the expected value has a '1' prefix
    const actualCode = await page.evaluate(getInnerText, 'editor');
    expect(actualCode).toContain(`1${v1State.state.editor.code}`);

    // Check compile configuration
    await page.click('#command-select');
    await page.click('#compile');

    expect(await page.evaluate(getInputValue, 'entrypoint')).toEqual(
      v1State.state.compile.entrypoint
    );

    // Check dry run configuration
    await page.click('#command-select');
    await page.click('#dry-run');

    expect(await page.evaluate(getInputValue, 'entrypoint')).toEqual(
      v1State.state.dryRun.entrypoint
    );
    expect(await page.evaluate(getInputValue, 'parameters')).toEqual(
      v1State.state.dryRun.parameters
    );
    expect(await page.evaluate(getInputValue, 'storage')).toEqual(
      v1State.state.dryRun.storage
    );

    // Check deploy configuration
    await page.click('#command-select');
    await page.click('#deploy');

    expect(await page.evaluate(getInputValue, 'entrypoint')).toEqual(
      v1State.state.deploy.entrypoint
    );
    expect(await page.evaluate(getInputValue, 'storage')).toEqual(
      v1State.state.deploy.storage
    );

    // Check evaluate function configuration
    await page.click('#command-select');
    await page.click('#evaluate-function');

    expect(await page.evaluate(getInputValue, 'entrypoint')).toEqual(
      v1State.state.evaluateFunction.entrypoint
    );
    expect(await page.evaluate(getInputValue, 'parameters')).toEqual(
      v1State.state.evaluateFunction.parameters
    );

    // Check evaluate value configuration
    await page.click('#command-select');
    await page.click('#evaluate-value');

    expect(await page.evaluate(getInputValue, 'entrypoint')).toEqual(
      v1State.state.evaluateValue.entrypoint
    );

    done();
  });
});
