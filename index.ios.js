import React, { Component } from 'react';
import { AppRegistry,
  StyleSheet,
  Text,
  View,
  TouchableOpacity,
  requireNativeComponent,
  findNodeHandle,
  TextInput,
  NativeModules,
  Dimensions
} from 'react-native';

import SyncRegistry from './lib/SyncRegistry';
const RNInfiniteScrollViewChildren = requireNativeComponent('RNInfiniteScrollViewChildren', null);

const dataObj = [{
  name: "Row 1",
  width: 850,
  height: 150,
},{
  name: "Row 2",
  width: 150,
  height: 30,
},{
  name: "Row 3",
  width: 500,
  height: 150,
},{
  name: "Row 4",
  width: 750,
  height: 150,
},{
  name: "Row 5",
  width: 150,
  height: 150,
},{
  name: "Row 6",
  width: 150,
  height: 150,
},{
  name: "Row 7",
  width: 150,
  height: 150,
},{
  name: "Row 8",
  width: 150,
  height: 150,
},{
  name: "Row 9",
  width: 150,
  height: 150,
},{
  name: "Row 10",
  width: 150,
  height: 150,
}];


class RNInfiniteScrollViewRowTemplate extends Component {
  render() {
    return (
      <View style={{padding: 10, width: this.props['item.width'], height: this.props['item.height'], backgroundColor: '#AAAA3377'}}>
        <TextInput
          style={{ backgroundColor: '#FFFFFF88', flexGrow: 1 }}
          editable={false}
          value={this.props['item.name']}
        />
      </View>
    );
  }
}

SyncRegistry.registerComponent('RNInfiniteScrollViewRowTemplate', () => RNInfiniteScrollViewRowTemplate, ['item.name','item.width','item.height', 'index']);
var IScrollManager = NativeModules.RNInfiniteScrollViewChildrenManager;

class example extends Component {
  componentWillMount() {
    setTimeout(() => {
      IScrollManager.prepareRows();
    }, 500);

    // setTimeout(() => {
    //   IScrollManager.prependDataToDataSource(['Row -4', 'Row -3', 'Row -2', 'Row -1', 'Row 0']);
    // }, 1000);

    // setTimeout(() => {
    //   IScrollManager.appendDataToDataSource(["Row 16", "Row 17", "Row 18"]);
    // }, 1000);

    // setTimeout(() => {
    //   IScrollManager.updateDataAtIndex(1, "row 33");
    // }, 1000);

    // setTimeout(() => {
    //   IScrollManager.setScrollerZoom(0.4, true);
    // }, 1000);

  }
  render() {
    /**
     * 3 loopModes supported:
     * 
     * no-loop,
     * repeat-empty,
     * repeat-edge,
     */
    return (
      <View style={styles.container}>
        <RNInfiniteScrollViewChildren
          style={{ top: 0, width: Dimensions.get('window').width, height: Dimensions.get('window').height, backgroundColor: 'pink' }}
          horizontal
          rowHeight={150}
          rowWidth={Dimensions.get('window').width}
          dynamicViewSizes
          numRenderRows={10}
          data={dataObj}
          loopMode="no-loop"
        />
      </View>
    );
  }
}


const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#D5D7FF',
  },
});

AppRegistry.registerComponent('example', () => example);
