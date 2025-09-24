// Helper functions for flow configuration

local flow(x) = "persistent://tg/flow/" + x;
local request(x) = "non-persistent://tg/request/" + x;
local response(x) = "non-persistent://tg/response/" + x;
local request_response(x) = {
  request: request(x),
  response: response(x),
};

{
    flow: flow,
    request: request,
    response: response,
    request_response: request_response,
}