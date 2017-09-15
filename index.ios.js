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




class RNInfiniteScrollViewRowTemplate extends Component {
  render() {
    return (
      <View style={{padding: 10, width: Dimensions.get('window').width, height: 80, backgroundColor: '#AAAA3377'}}>
        <TextInput
          style={{ backgroundColor: '#FFFFFF88', flexGrow: 1 }}
          editable={false}
          value={this.props.item}
        />
      </View>
    );
  }
}

SyncRegistry.registerComponent('RNInfiniteScrollViewRowTemplate', () => RNInfiniteScrollViewRowTemplate, ['item']);
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
          paging
          numRenderRows={10}
          data={["Row 1", "Row 2", "Row 3", "Row 4", "Row 5", "Row 6", "Row 7", "Row 8", "Row 9", "Row 10", "Row 11", "Row 12", "Row 13", "Row 14", "Row 15"]}
          loopMode="no-loop"
          initialPosition={6}
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
